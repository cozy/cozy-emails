{NotFound, AccountConfigError, TimeoutError} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'imap:pool')
rawImapLog = require('../utils/logging')(prefix: 'imap:raw')
Account = require '../models/account'
Imap = require './connection'

connectionID = 1

class ImapPool

    # static methods

    @instances = {}

    # get the pool for a given account
    @get: (accountID) ->
        @instances[accountID] ?= new ImapPool accountID
        return @instances[accountID]

    # create a temporary pool to test a connection
    @test: (account, callback) ->
        pool = new ImapPool account
        pool.doASAP (imap, cbRelease) ->
            cbRelease null, 'OK'
        , (err) ->
            pool.destroy()
            callback err


    constructor: (accountOrID) ->
        if typeof accountOrID is 'string'
            log.debug @id, "new pool #{accountOrID}"
            @id = @accountID = accountOrID
            @account = null
        else
            log.debug @id, "new pool Object##{accountOrID.id}"
            @id = @accountID = accountOrID.id
            @account = accountOrID

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
        delete ImapPool.instances[@accountID]

    _removeFromPool: (connection) ->
        log.debug @id, "remove #{connection.connectionID} from pool"
        index = @connections.indexOf connection
        @connections.splice index, 1 if index > -1
        index = @freeConnections.indexOf connection
        @freeConnections.splice index, 1

    _getAccount: ->
        log.debug @id, "getAccount"
        Account.find @accountID, (err, account) =>
            return @_giveUp err if err
            return @_giveUp new NotFound "Account #{@accountID}" unless account
            @account = account
            @_deQueue()

    _makeConnection: ->
        log.debug @id, "makeConnection"
        @connecting++

        options =
            user       : @account.login
            password   : @account.password
            host       : @account.imapServer
            port       : parseInt @account.imapPort
            tls        : not @account.imapSSL? or @account.imapSSL
            tlsOptions : rejectUnauthorized : false
            # debug      : (content) -> rawImapLog.debug content

        imap = new Imap options

        onConnError = @_onConnectionError.bind this, imap
        imap.connectionID = 'conn' + connectionID++
        imap.connectionName = "#{options.host}:#{options.port}"

        imap.on 'error', onConnError
        imap.once 'ready', =>
            log.debug @id, "imap ready"
            imap.removeListener 'error', onConnError
            clearTimeout wrongPortTimeout
            @_onConnectionSuccess imap

        imap.connect()

        # timeout when wrong port is too high
        # bring it to 10s
        wrongPortTimeout = setTimeout =>
            log.debug @id, "timeout 10s"
            imap.removeListener 'error', onConnError
            onConnError new TimeoutError "Timeout connecting to #{@account?.imapServer}:#{@account?.imapPort}"
            imap.destroy()

        ,10000


    _onConnectionError: (connection, err) ->
        log.debug @id, "connection error on #{connection.connectionName}"
        # we failed to establish a new connection
        @connecting--
        @failConnectionCounter++
        # try again in 5s
        if @failConnectionCounter > 2
            @_giveUp _typeConnectionError err
        else
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
        log.error "error on active imap socket on #{connection.connectionName}", err.stack
        @_removeFromPool connection
        try connection.destroy()

    _onActiveClose: (connection, err) ->
        log.error "active connection #{connection.connectionName} closed", err.stack
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
        delete @account
        task = @tasks.pop()
        while task
            task.callback err
            task = @tasks.pop()

    _deQueue: =>
        free = @freeConnections.length > 0
        full = @connections.length + @connecting >= @parallelism
        moreTasks = @tasks.length > 0

        unless @account
            log.debug @id, "_deQueue/needaccount"
            return @_getAccount()

        if @account.isTest()
            log.debug @id, "_deQueue/test"
            if moreTasks
                task = @tasks.pop()
                task.callback? null
                process.nextTick @_deQueue

            return

        if moreTasks
            if @closingTimer
                log.debug @id, "_deQueue/stopTimer"
                clearTimeout @closingTimer

            if free
                log.debug @id, "_deQueue/free"
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
                log.debug @id, "_deQueue/notfull"
                @_makeConnection()

            # else queue is full, just wait

        else
            log.debug @id, "_deQueue/startTimer"
            @closingTimer ?= setTimeout @_closeConnections, 5000




    _typeConnectionError = (err) ->
        # if the know the type of error, clean it up for the user

        typed = err

        if err.textCode is 'AUTHENTICATIONFAILED'
            typed =  new AccountConfigError 'auth'

        if err.code is 'ENOTFOUND' and err.syscall is 'getaddrinfo'
            typed = new AccountConfigError 'imapServer'

        if err.source is 'timeout-auth'
            # @TODO : this can happen for other reason,
            # we need to retry before throwing
            typed = new AccountConfigError 'imapTLS'

        if err instanceof TimeoutError
            typed = new AccountConfigError 'imapPort'

        return err


    _wrapOpenBox: (cozybox, operation) ->

        return wrapped = (imap, callback) =>
            log.debug @id, "begin wrapped task"

            imap.openBox cozybox.path, (err, imapbox) =>
                log.debug @id, "wrapped box opened", err
                return callback err if err

                unless imapbox.persistentUIDs
                    return callback new Error 'UNPERSISTENT UID'

                # check the uidvalidity
                oldUidvalidity = cozybox.uidvalidity
                newUidvalidity = imapbox.uidvalidity
                if oldUidvalidity and oldUidvalidity isnt newUidvalidity
                    log.error "uidvalidity has changed"

                    # we got a problem, recover
                    # @TODO : this can be long, prevent timeout
                    cozybox.recoverChangedUIDValidity imap, (err) ->
                        changes = uidvalidity: newUidvalidity
                        cozybox.updateAttributes changes, (err) ->
                            # we have recovered, try again
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



module.exports =
    get: (accountID) -> ImapPool.get accountID
    test: (accountID, cb) -> ImapPool.test accountID, cb




# use me
# ImapPool = require 'this-file'
# pool = ImapPool.get(accountID)
# pool.doASAP (imap, cb) ->
#     imap.doStuff cb
# , callback

# pool.usingBox box, (imap, cb) ->
#     imap.doStuff cb
# , callback
