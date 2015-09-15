errors =  require '../utils/errors'
{AccountConfigError, TimeoutError, PasswordEncryptedError} = errors
log = require('../utils/logging')(prefix: 'imap:pool')
rawImapLog = require('../utils/logging')(prefix: 'imap:raw')
Account = require '../models/account'
Imap = require './connection'
xoauth2 = require 'xoauth2'
async = require "async"
accountConfigTools = require '../imap/account2config'
{makeIMAPConfig, forceOauthRefresh, forceAccountFetch} = accountConfigTools
Scheduler = require '../processes/_scheduler'
RecoverChangedUIDValidity = require '../processes/recover_change_uidvalidity'

connectionID = 1

module.exports = class ImapPool

    constructor: (account) ->
        log.debug @id, "new pool Object##{account.id}"
        @id = account.id or 'tmp'
        @account = account

        @parallelism = 1
        @tasks = []             # tasks waiting to be processed
        @pending = {}           # tasks being processed
        @failConnectionCounter = 0
        @connecting = 0
        @connections = []       # all connections
        @freeConnections = []   # connections not in use

    destroy: ->
        log.debug @id, "destroy"
        clearTimeout @closingTimer if @closingTimer
        @_closeConnections()

    _removeFromPool: (connection) ->
        log.debug @id, "remove #{connection.connectionID} from pool"
        index = @connections.indexOf connection
        @connections.splice index, 1 if index > -1
        index = @freeConnections.indexOf connection
        @freeConnections.splice index, 1

    _makeConnection: ->
        log.debug @id, "makeConnection"
        @connecting++

        makeIMAPConfig @account, (err, options) =>
            log.error "oauth generation error", err if err
            return @_onConnectionError connectionName: '', err if err

            log.debug "Attempting connection"
            password = options.password
            if password then options.password = "****"
            log.debug options
            if password then options.password = password

            imap = new Imap options
            onConnError = @_onConnectionError.bind this, imap
            imap.connectionID = 'conn' + connectionID++
            imap.connectionName = "#{options.host}:#{options.port}"

            imap.on 'error', onConnError
            imap.once 'ready', =>
                imap.removeListener 'error', onConnError
                clearTimeout @wrongPortTimeout
                @_onConnectionSuccess imap

            imap.connect()

            # timeout when wrong port is too high
            # bring it to 10s
            @wrongPortTimeout = setTimeout =>
                log.debug @id, "timeout 10s"
                imap.removeListener 'error', onConnError
                onConnError new TimeoutError "Timeout connecting to " +
                    "#{@account?.imapServer}:#{@account?.imapPort}"
                imap.destroy()

            , 10000


    _onConnectionError: (connection, err) ->
        log.debug @id, "connection error on #{connection.connectionName}"
        log.debug "RAW ERROR", err
        # we failed to establish a new connection
        clearTimeout @wrongPortTimeout
        @connecting--
        @failConnectionCounter++

        isAuth = err.textCode is 'AUTHENTICATIONFAILED'

        if err instanceof PasswordEncryptedError
            @_giveUp err

        else if @failConnectionCounter > 2
            # give up
            @_giveUp _typeConnectionError err
        else if err.source is 'autentification' and
                                             @account.oauthProvider is 'GMAIL'
            # refresh accessToken
            forceOauthRefresh @account, @_deQueue

        # TMP : this should be removed when data-system#161 is widely deployed
        else if isAuth and @account.id and @failConnectionCounter is 1
            forceAccountFetch @account, @_deQueue

        else
            # try again in 5s
            setTimeout @_deQueue, 5000

    _onConnectionSuccess: (connection) ->
        log.debug @id, "connection success"
        connection.once 'close', @_onActiveClose.bind this, connection
        connection.once 'error', @_onActiveError.bind this, connection

        @connections.push connection
        @freeConnections.push connection
        @connecting--
        @failConnectionCounter = 0
        process.nextTick @_deQueue

    _onActiveError: (connection, err) ->
        name = connection.connectionName
        log.error "error on active imap socket on #{name}", err
        @_removeFromPool connection
        try connection.destroy()

    _onActiveClose: (connection, err) ->
        log.error "active connection #{connection.connectionName} closed", err
        task = @pending[connection.connectionID]
        if task
            delete @pending[connection.connectionID]
            task.callback? err or new Error 'connection was closed'
            task.callback = null

        @_removeFromPool connection

    _closeConnections: =>
        log.debug @id, "closeConnections"
        @closingTimer = null
        connection = @connections.pop()
        while connection
            connection.expectedClosing = true
            connection.end()
            connection = @connections.pop()

        @freeConnections = []

    _giveUp: (err) ->
        log.debug @id, "giveup", err
        task = @tasks.pop()
        while task
            task.callback err
            task = @tasks.pop()

    _deQueue: =>
        free = @freeConnections.length > 0
        full = @connections.length + @connecting >= @parallelism
        moreTasks = @tasks.length > 0

        if @account.isTest()
            # log.debug @id, "_deQueue/test"
            if moreTasks
                task = @tasks.pop()
                task.callback? null
                process.nextTick @_deQueue

            return

        if moreTasks
            if @closingTimer
                # log.debug @id, "_deQueue/stopTimer"
                clearTimeout @closingTimer

            if free
                # log.debug @id, "_deQueue/free"
                imap = @freeConnections.pop()
                task = @tasks.pop()

                @pending[imap.connectionID] = task

                task.operation imap, (err) =>

                    args = (arg for arg in arguments)

                    @freeConnections.push imap
                    delete @pending[imap.connectionID]

                    # prevent imap catching callback errors
                    process.nextTick ->
                        task.callback?.apply null, args
                        task.callback = null
                    process.nextTick @_deQueue

            else if not full
                # log.debug @id, "_deQueue/notfull"
                @_makeConnection()

            # else queue is full, just wait

        else
            # log.debug @id, "_deQueue/startTimer"
            @closingTimer ?= setTimeout @_closeConnections, 5000




    _typeConnectionError = (err) ->
        # if the know the type of error, clean it up for the user

        typed = err

        if err.textCode is 'AUTHENTICATIONFAILED'
            typed =  new AccountConfigError 'auth', err

        if err.code is 'ENOTFOUND' and err.syscall is 'getaddrinfo'
            typed = new AccountConfigError 'imapServer', err

        if err.code is 'EHOSTUNREACH'
            typed = new AccountConfigError 'imapServer', err

        if err.source is 'timeout-auth'
            # @TODO : this can happen for other reason,
            # we need to retry before throwing
            typed = new AccountConfigError 'imapTLS', err

        if err instanceof TimeoutError
            typed = new AccountConfigError 'imapPort', err

        return typed


    _wrapOpenBox: (cozybox, operation) ->

        return wrapped = (imap, callback) =>
            # log.debug @id, "begin wrapped task"

            imap.openBox cozybox.path, (err, imapbox) =>
                # log.debug @id, "wrapped box opened", err
                return callback err if err

                unless imapbox.persistentUIDs
                    return callback new Error 'UNPERSISTENT UID'

                # check the uidvalidity
                oldUidvalidity = cozybox.uidvalidity
                newUidvalidity = imapbox.uidvalidity
                if oldUidvalidity and oldUidvalidity isnt newUidvalidity
                    log.error "uidvalidity has changed"

                    recover = new RecoverChangedUIDValidity
                        newUidvalidity: newUidvalidity
                        mailbox: cozybox
                        imap: imap

                    recover.run (err) ->
                        log.error err if err
                        wrapped imap, callback

                else
                    # perform the wrapped operation
                    operation imap, imapbox, (err, arg1, arg2, arg3) =>
                        log.debug @id, "wrapped operation completed"
                        return callback err if err

                        # store the uid validity
                        unless oldUidvalidity
                            changes = uidvalidity: newUidvalidity
                            cozybox.updateAttributes changes, (err) ->
                                return callback err if err
                                callback null, arg1, arg2, arg3

                        else
                            callback null, arg1, arg2, arg3



    doASAP: (operation, callback) ->
        @tasks.unshift {operation, callback}
        @_deQueue()

    doLater: (operation, callback) ->
        @tasks.push {operation, callback}
        @_deQueue()

    doASAPWithBox: (cozybox, operation, callback) ->
        operation = @_wrapOpenBox cozybox, operation
        @tasks.unshift {operation, callback}
        @_deQueue()

    doLaterWithBox: (cozybox, operation, callback) ->
        operation = @_wrapOpenBox cozybox, operation
        @tasks.push {operation, callback}
        @_deQueue()

