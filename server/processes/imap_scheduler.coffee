log = require('../utils/logging')(prefix: 'imap:scheduler')

# Public : see bluebird
class Promise # reference for biscotto, @TODO : move it away

ImapPromised = require './imap_promisified'
ImapReporter = require './imap_reporter'
Promise = require 'bluebird'
_ = require 'lodash'
{UIDValidityChanged} = require '../utils/errors'
Message = require '../models/message'
mailutils = require '../utils/jwz_tools'
Account = require '../models/account'

# Public: The imap scheduler is responsible to maintain
# a list of task than need to be executed.
# It will create and destroy its @imap connection
# ASAP tasks are run first
#
# Examples
#
#  scheduler = ImapScheduler.instanceFor account
#  pResult = scheduler.doASAP (imap) ->
#    imap.doSomething()
module.exports = class ImapScheduler

    # static function, we have 1 ImapScheduler by imap server
    @instances = {}

    # Public: get the singleton instance of {ImapScheduler}
    # for the passed {Account}
    #
    # accountID - the id of the {Account} to get the instance for
    # account - if the scheduler doesnt exist, create it using account
    #
    # Returns an {ImapScheduler} linked to this account
    @instanceFor = (accountID, account) ->
        if scheduler = @instances[accountID]
            return Promise.resolve scheduler

        Promise.resolve account or Account.findPromised accountID
        .then (account) =>
            scheduler = if (not account?) or account.isTest() then new TestScheduler()
            else new ImapScheduler account.makeImapConfig()
            @instances[accountID] = scheduler
            return scheduler

    # actual IMAP tasks
    tasks: []
    pendingTask: null

    # Private: create a new connection for this
    # scheduler instance
    #
    # config - imap config
    #
    # Returns a {Promise} for the connected imap object
    constructor: (config) ->
        @config = config
        @accoutnID = config._id

    # Private: create a new connection for this
    # scheduler instance
    #
    # Returns a {Promise} for the connected imap object
    createNewConnection: ->
        log.info "OPEN IMAP CONNECTION", @config.label

        @imap = new ImapPromised @config

        @imap.onTerminated = (err) =>
            log.error 'IMAP TERMINATED', err
            if @pendingTask
                @_rejectPending new Error 'connection closed'
            if @closingTimer
                clearTimeout @closingTimer
                @closingTimer = null
            @closeConnection true

        @imap.waitConnected
            .catch (err) =>
                log.error "FAILED TO CONNECT", err, @tasks.length
                # we cant connect, drop the tasks
                task.reject err while task = @tasks.shift()
                throw err
            .tap => @_dequeue()

    # Private: close the connection
    #
    # hard - {Boolean} either to force close the socket
    #         or wait for it to connect
    #
    # Returns a {Promise} for the connected imap object
    closeConnection: (hard) =>
        @imap.end(hard).then =>
            log.info "CLOSED CONNECTION ", (if hard then "HARD" else "")
            @imap = null
            @_dequeue()

    # Public: run generator as soon as the connection
    # is available
    #
    # gen - a {Function} that returns a {Promise}
    #
    # Returns a {Promise} for the return value of gen
    doASAP: (gen) -> @queue true, gen

    # Public: run generator later when the connection
    # is available
    #
    # gen - a {Function} that returns a {Promise}
    #
    # Returns a {Promise} for the return value of gen
    doLater: (gen) -> @queue false, gen

    # Public: run generator later when the connection
    # is available
    #
    # gen - a {Function} that returns a {Promise}
    #
    # Returns a {Promise} for the return value of gen
    queue: (urgent = false, gen) ->
        return new Promise (resolve, reject) =>
            fn = if urgent then 'unshift' else 'push'
            @tasks[fn]
                attempts: 0
                generator: gen
                resolve: resolve
                reject: reject

            @_dequeue()


    # Public: utility function for actions in a box
    # handle the case where UIDValidity has changed
    #
    # box - {Mailbox} to work in
    # gen - a {Function} that returns a Promise
    #
    # Returns a {Promise} for the return value of gen
    doASAPWithBox: (box, gen) -> @queueWithBox true, box, gen

    # Public: utility function for actions in a box
    # handle the case where UIDValidity has changed
    #
    # box - {Mailbox} to work in
    # gen - a {Function} that returns a Promise
    #
    # Returns a {Promise} for the return value of gen
    doLaterWithBox: (box, gen) -> @queueWithBox false, box, gen

    # Private: utility function for actions in a box
    # handle the case where UIDValidity has changed
    #
    # box - {Mailbox} to work in
    # gen - a {Function} that returns a Promise
    #
    # Returns a {Promise} for the return value of gen
    queueWithBox: (urgent, box, gen) ->
        @queue urgent, (imap) ->
            imap.openBox box.path
            .then (imapbox) ->
                unless imapbox.persistentUIDs
                    throw new Error 'UNPERSISTENT UID NOT SUPPORTED'

                # not the same uidvalidity
                if box.uidvalidity and box.uidvalidity isnt imapbox.uidvalidity
                    throw new UIDValidityChanged imapbox.uidvalidity

                # call the wrapped generator
                gen imap, imapbox
                .tap -> unless box.uidvalidity
                    # we store the uidvalidity
                    log.info "FIRST UIDVALIDITY", imapbox.uidvalidity
                    box.updateAttributesPromised
                        uidvalidity: imapbox.uidvalidity

        # if UIDValidity has changed, we recover
        .catch UIDValidityChanged, (err) =>
            log.info "UIDVALIDITY", box.uidvalidity, err.newUidvalidity
            log.warn "UID VALIDITY HAS CHANGED, RECOVERING"

            @doASAP (imap) ->
                box.recoverChangedUIDValidity imap
            .then ->
                box.updateAttributesPromised
                    uidvalidity: err.newUidvalidity

            .then =>
                log.warn "RECOVERED"
                @queueWithBox urgent, box, gen

    # Private: solve the pending task promise
    #
    # result - the result to solve it with
    #
    # Returns: {void}
    _resolvePending: (result) =>
        @pendingTask.resolve result
        @pendingTask = null
        setTimeout @_dequeue, 1

    # Private: solve the pending task promise
    #
    # err - the {Error} to reject the promise with
    #
    # Returns: {void}
    _rejectPending: (err) =>
        @pendingTask.reject err
        @pendingTask = null
        setTimeout @_dequeue, 1


    # Private: handle next step of the processing
    # - open and close the imap connection as appropriate
    # - timeout every task for 2min
    #
    #
    # Returns: {void}
    _dequeue: =>

        # already working, ignore
        return false if @pendingTask

        # connection in process
        return false if @imap?.waitConnected.isPending()
        return false if @imap?.waitEnding?.isPending()

        moreTasks = @tasks.length isnt 0

        # nothing to do
        if not moreTasks and not @imap
            return false

        # we are done with current tasks
        if @imap and not moreTasks
            @closingTimer ?= setTimeout @closeConnection, 3000
            return false

        # a new task was added and we have closing timer
        # stop it
        if @closingTimer
            clearTimeout @closingTimer
            @closingTimer = null

        # we need a connection
        if moreTasks and not @imap
            @createNewConnection()
            return false

        # we have a task and connection, lets get to work
        @pendingTask = @tasks.shift()
        Promise.resolve @pendingTask.generator(@imap)
        # if a task takes more than a minute
        # assume its broken and nuke the socket
        .timeout 120000
        .catch Promise.TimeoutError, (err) =>
            log.error "TASK GOT STUCKED"
            @closeConnection true
            throw err

        .then @_resolvePending, @_rejectPending


class TestScheduler

    doASAP: (gen) -> Promise.resolve null
    doASAPWithBox: (gen) -> Promise.resolve null
    doLater: (gen) -> Promise.resolve null
    doLaterWithBox: (gen) -> Promise.resolve null
