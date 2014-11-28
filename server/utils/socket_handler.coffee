ImapReporter = require '../imap/reporter'
log = require('../utils/logging')('sockethandler')
ioServer = require 'socket.io'

io = null
sockets = []

SocketHandler = exports

SocketHandler.setup = (app, server) ->
    io = ioServer server
    ImapReporter.setIOReference io
    io.on 'connection', handleNewClient


SocketHandler.notify = (type, data) ->
    log.info "notify", type, data.toString()
    if type in ['message.update', 'message.create']
        # we cant just spam the client with all
        # message events, check if the message is in
        # client current's view
        for socket in sockets when inScope socket, data
            socket.emit type, data

    else
        io?.emit type, data


# using DS events imply one more query for each update
# instead we monkeypatch JDB
SocketHandler.wrapModel = (Model, docType) ->

    _oldCreate = Model.create
    Model.create = (data, callback) ->
        _oldCreate.call Model, data, (err, created) ->
            unless err
                SocketHandler.notify "#{docType}.create", created
            callback err, created

    _oldUpdateAttributes = Model::updateAttributes
    Model::updateAttributes = (data, callback) ->
        _oldUpdateAttributes.call this, data, (err, updated) ->
            unless err
                SocketHandler.notify "#{docType}.update", updated
            callback err, updated

    _oldDestroy = Model::destroy
    Model::destroy = (callback) ->
        id = @id
        _oldDestroy.call this, (err) ->
            unless err
                SocketHandler.notify "#{docType}.delete", id
            callback err



inScope = (socket, data) ->
    log.info "inscope", socket.scope_mailboxID, Object.keys data.mailboxIDs
    (socket.scope_mailboxID in Object.keys data.mailboxIDs) and
    socket.scope_before < data.date

handleNewClient = (socket) =>
    log.debug 'handleNewClient', socket.id
    socket.on 'mark_ack', ImapReporter.acknowledge
    socket.on 'change_scope', (scope) ->
        updateClientScope socket, scope
    socket.on 'disconnect', ->
        forgetClient socket

    sockets.push socket

updateClientScope = (socket, scope) ->
    log.warn 'updateClientScope', socket.id, scope
    socket.scope_before = new Date(scope.before or 0)
    socket.scope_mailboxID = scope.mailboxID

forgetClient = (socket) ->
    log.debug "forgetClient", socket.id
    index = sockets.indexOf socket
    sockets = sockets.splice index, 1

