log = require('../utils/logging')(prefix: 'imap:scheduler')

ImapPromised = require './imap_promisified'
ImapReporter = require './imap_reporter'
Promise = require 'bluebird'
_ = require 'lodash'
{UIDValidityChanged} = require '../utils/errors'
Message = require '../models/message'
mailutils = require '../utils/jwz_tools'

# The imap scheduler is responsible to maintain
# a list of task than need to be executed.
# It will create and destroy its @imap connection
# ASAP tasks are run first

# usage :
# scheduler = ImapScheduler.instanceFor account
# pResult = scheduler.doASAP (imap) -> imap.doSomething()

module.exports = class ImapScheduler

    # static function, we have 1 ImapScheduler by imap server
    @instances = {}
    @instanceFor: (account) ->
        @instances[account.imapServer] ?= new ImapScheduler account
        return @instances[account.imapServer]

    # actual IMAP tasks
    tasks: []
    pendingTask: null

    constructor: (@account) ->
        Account = require '../models/account'
        unless @account instanceof Account
            @account = new Account @account

    createNewConnection: ->
        log.info "OPEN IMAP CONNECTION", @account.label

        @imap = new ImapPromised
            user: @account.login
            password: @account.password
            host: @account.imapServer
            port: parseInt @account.imapPort
            tls: not @account.imapSecure? or @account.imapSecure
            tlsOptions: rejectUnauthorized: false

        @imap.onTerminated = =>
            @_rejectPending new Error 'connection closed'
            @closeConnection()

        @imap.waitConnected
            .catch (err) =>
                log.error "FAILED TO CONNECT", err.stack
                # we cant connect, drop the tasks
                task.reject err while task = @tasks.shift()
                throw err
            .tap => @_dequeue()

    closeConnection: (hard) =>
        log.info "CLOSING CONNECTION", (if hard then "HARD" else "")
        @imap.end(hard).then =>
            log.info "CLOSED CONNECTION"
            @imap = null
            @_dequeue()

    # add task to queue
    # gen is a function that returns a promise
    doASAP: (gen) -> @queue true, gen
    doLater: (gen) -> @queue false, gen
    queue: (urgent = false, gen) ->
        return new Promise (resolve, reject) =>
            fn = if urgent then 'unshift' else 'push'
            @tasks[fn]
                attempts: 0
                generator: gen
                resolve: resolve
                reject: reject

            @_dequeue()


    # utility function for actions in a box
    # handle the case where UIDValidity has changed
    doASAPWithBox: (box, gen) -> @queueWithBox true, box, gen
    doLaterWithBox: (box, gen) -> @queueWithBox false, box, gen
    queueWithBox: (urgent, box, gen) ->
        @queue urgent, (imap) ->

            uidvalidity = null

            imap.openBox box.path
            .then (imapbox) ->
                unless imapbox.persistentUIDs
                    throw new Error 'UNPERSISTENT UID NOT SUPPORTED'

                log.info "UIDVALIDITY", box.uidvalidity, imapbox.uidvalidity

                # not the same uidvalidity
                if box.uidvalidity and box.uidvalidity isnt imapbox.uidvalidity
                    throw new UIDValidityChanged imapbox.uidvalidity

                # call the wrapped generator
                gen imap
                .tap -> unless box.uidvalidity
                    # we store the uidvalidity
                    log.info "FIRST UIDVALIDITY", imapbox.uidvalidity
                    box.updateAttributesPromised
                        uidvalidity: imapbox.uidvalidity

        # if UIDValidity has changed, we recover
        .catch UIDValidityChanged, (err) =>
            log.warn "UID VALIDITY HAS CHANGED, RECOVERING"

            @doASAP (imap) => 
                recoverChangedUIDValidity imap, box, @account._id
            .then ->
                box.updateAttributesPromised
                    uidvalidity: err.newUidvalidity
            
            .then =>
                log.warn "RECOVERED"
                @queueWithBox urgent, box, gen

    _resolvePending: (result) =>
        @pendingTask.resolve result
        @pendingTask = null
        setTimeout @_dequeue, 1

    _rejectPending: (err) =>
        @pendingTask.reject err
        @pendingTask = null
        setTimeout @_dequeue, 1

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
            @closeConnection()
            return false

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

recoverChangedUIDValidity = (imap, box, accountID) ->
    reporter = ImapReporter.addUserTask
        code: 'fix-changed-uidvalidity'
        box: box.path

    imap.openBox(box.path)
    .then -> imap.fetchBoxMessageIds()
    .then (map) ->
        Promise.serie _.keys(map), (newUID) ->
            messageID = mailutils.normalizeMessageID map[newUID]
            Message.rawRequestPromised 'byMessageId',
                key: [accountID, messageID]
                include_docs: true
            .get(0)
            .then (row) ->
                return unless row
                console.log "MATCH"
                mailboxIDs = row.mailboxIDs
                mailboxIDs[box.id] = newUID
                msg = new Message(row.doc)
                msg.updateAttributesPromised {mailboxIDs}

# @TODO, put this elsewhere
Promise.serie = (items, mapper) ->
    Promise.map items, mapper, concurrency: 1