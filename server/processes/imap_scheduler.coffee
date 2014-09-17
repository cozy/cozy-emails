ImapPromised = require './imap_promisified'
Promise = require 'bluebird'

# The imap scheduler is responsible to maintain
# a list of task than need to be executed.
# It will create and destroy its @imap connection
# ASAP tasks are run first
# promiseGenerator is a function that returns a promise

# usage :
# scheduler = ImapScheduler.instanceFor account
# pResult = scheduler.doASAP (imap) -> imap.doSomething()

module.exports = class ImapScheduler

    # static function, we have 1 ImapScheduler by imap server
    @instances = {}
    @instanceFor: (account) ->
        @instances[account.imapServer] ?= new ImapScheduler account
        return @instances[account.imapServer]
    @summary = ->
        out = {}
        for server, instance of @instances
            out[server] = instance.tasks
        return out

    tasks: []
    pendingTask: null

    constructor: (@account) ->
        Account = require '../models/account'
        unless @account instanceof Account
            @account = new Account @account

    createNewConnection: ->
        console.log "OPEN IMAP CONNECTION", @account.label
        @imap = new ImapPromised
            user: @account.login
            password: @account.password
            host: @account.imapServer
            port: parseInt @account.imapPort
            tls: not @account.imapSecure? or @account.imapSecure
            tlsOptions: rejectUnauthorized: false
            # debug: console.log

        @imap.onTerminated = =>
            @_rejectPending new Error 'connection closed'
            @closeConnection()

        @imap.waitConnected
            .catch (err) =>
                console.log "FAILED TO CONNECT", err.stack
                # we cant connect, drop the tasks
                task.reject err while task = @tasks.shift()
                throw err
            .tap => @_dequeue()

    closeConnection: (hard) =>
        console.log "CLOSING CONNECTION"
        @imap.end(hard).then =>
            console.log "CLOSED CONNECTION"
            @imap = null
            @_dequeue()

    # add task to queue
    doASAP: (gen) -> @queue gen, true
    doLater: (gen) -> @queue gen, false
    queue: (gen, urgent = false) ->
        return new Promise (resolve, reject) =>
            fn = if urgent then 'unshift' else 'push'
            @tasks[fn]
                attempts: 0
                generator: gen
                resolve: resolve
                reject: reject

            @_dequeue()

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
        .timeout 60000
        .catch Promise.TimeoutError, (err) =>
            @closeConnection true
            throw err

        .then @_resolvePending, @_rejectPending


# @TODO, put this elsewhere
Promise.serie = (items, mapper) ->
    Promise.map items, mapper, concurrency: 1