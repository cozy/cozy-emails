log = require('../utils/logging')('sockethandler')
ioServer = require 'socket.io'
ramStore = require '../models/store_account_and_boxes'
Scheduler = require '../processes/_scheduler'
stream = require 'stream'
_ = require 'lodash'
Acccount = require '../models/account'
Mailbox = require '../models/mailbox'
Message = require '../models/message'

io = null
sockets = []
processSummaryCooldown = null

SocketHandler = exports

SocketHandler.setup = (app, server) ->
    io = ioServer server
    io.on 'connection', handleNewClient

    Acccount.on 'create', (created) ->
        created = ramStore.getAccountClientObject created.id
        io.emit 'account.create', created

    Acccount.on 'update', (updated, old) ->
        updated = ramStore.getAccountClientObject updated.id
        io.emit 'account.update', updated, old

    Acccount.on 'delete', (id, deleted) ->
        io.emit 'account.delete', id, deleted

    Mailbox.on 'create', (created) ->
        created = ramStore.getMailboxClientObject created.id
        io.emit 'mailbox.create', created

    Mailbox.on 'update', (updated, old) ->
        updated = ramStore.getMailboxClientObject updated.id
        io.emit 'mailbox.update', updated, old

    Mailbox.on 'delete', (id, deleted) ->
        io.emit 'mailbox.delete', id, deleted

    Message.on 'create', (created) ->
        created = created.toClientObject()
        io.emit 'message.create', created
        for socket in sockets when inScope(socket, created)
            socket.emit 'message.create', created

    Message.on 'update', (updated, old) ->
        updated = updated.toClientObject()
        io.emit 'message.update', updated, old
        for socket in sockets
            if inScope(socket, updated) or inScope(socket, old)
                socket.emit 'message.update', updated

    Message.on 'delete', (id, deleted) ->
        io.emit 'message.delete', id, deleted


    Scheduler.on 'change', ->
        if processSummaryCooldown
            return true
        else
            io.emit 'refresh.update', Scheduler.clientSummary()
            processSummaryCooldown = true
            setTimeout (-> processSummaryCooldown = false) , 500


    onAccountChanged = (accountID) ->
        updated = ramStore.getAccountClientObject accountID
        io.emit 'account.update', updated if updated

    onAccountChangedDebounced = _.debounce onAccountChanged, 500,
        leading: true
        trailing: true

    ramStore.on 'change', onAccountChangedDebounced




inScope = (socket, data) ->
    (socket.scope_mailboxID in Object.keys data.mailboxIDs) and
    socket.scope_before < data.date

handleNewClient = (socket) ->
    log.debug 'handleNewClient', socket.id

    # update the client refreshes status
    socket.emit 'refreshes.status', Scheduler.clientSummary()

    socket.on 'change_scope', (scope) ->
        updateClientScope socket, scope
    socket.on 'disconnect', ->
        forgetClient socket

    sockets.push socket

updateClientScope = (socket, scope) ->
    log.debug 'updateClientScope', socket.id, scope
    socket.scope_before = new Date(scope.before or 0)
    socket.scope_mailboxID = scope.mailboxID

forgetClient = (socket) ->
    log.debug "forgetClient", socket.id
    index = sockets.indexOf socket
    if index isnt -1
        sockets = sockets.splice index, 1

