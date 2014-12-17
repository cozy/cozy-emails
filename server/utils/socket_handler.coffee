ImapReporter = require '../imap/reporter'
log = require('../utils/logging')('sockethandler')
ioServer = require 'socket.io'
Mailbox = require '../models/mailbox'
stream = require 'stream'

io = null
sockets = []

SocketHandler = exports

SocketHandler.setup = (app, server) ->
    io = ioServer server
    ImapReporter.setIOReference io
    io.on 'connection', handleNewClient


SocketHandler.notify = (type, data, olddata) ->
    log.info "notify", type, data.toString()
    if type in ['message.update', 'message.create']
        # we cant just spam the client with all
        # message events, check if the message is in
        # client current's view
        for socket in sockets
            if inScope(socket, data) or (olddata and inScope(socket, olddata))
                socket.emit type, data

    else if type is 'mailbox.update'
        # include the mailbox counts
        Mailbox.getCounts data.id, (err, results) ->
            console.log results, data.id, data
            if thisbox = results[data.id]
                {total, unread, recent} = thisbox
                data.nbTotal  = total
                data.nbUnread = unread
                data.nbRecent = recent
            io?.emit type, data

    else
        io?.emit type, data


# using DS events imply one more query for each update
# instead we monkeypatch JDB
SocketHandler.wrapModel = (Model, docType) ->

    _oldCreate = Model.create
    Model.create = (data, callback) ->
        _oldCreate.call Model, data, (err, created) ->
            unless err
                raw = created.toObject()
                SocketHandler.notify "#{docType}.create", raw
            callback err, created

    _oldUpdateAttributes = Model::updateAttributes
    Model::updateAttributes = (data, callback) ->
        old = @toObject()
        _oldUpdateAttributes.call this, data, (err, updated) ->
            unless err
                raw = updated.toObject()
                SocketHandler.notify "#{docType}.update", raw, old
            callback err, updated

    _oldDestroy = Model::destroy
    Model::destroy = (callback) ->
        old = @toObject()
        id = old.id
        _oldDestroy.call this, (err) ->
            unless err
                SocketHandler.notify "#{docType}.delete", id, old
            callback err

    # should not be here
    _oldRawRequest = Model.rawRequest
    Model.rawRequest = (name, params, callback) ->
        _oldRawRequest name, params, (err, result) ->
            callback err, result?.rows or result


    _oldAttachBinary = Model::attachBinary
    Model::attachBinary = (path, data, callback) ->
        # pouchdb-adapter dont understand buffer
        if path instanceof Buffer
            bufferStream = new stream.Transform()
            bufferStream.push path
            bufferStream.end()
            path = bufferStream

        _oldAttachBinary.call this, path, data, callback




inScope = (socket, data) ->
    # log.info "inscope", socket.scope_mailboxID, Object.keys data.mailboxIDs
    (socket.scope_mailboxID in Object.keys data.mailboxIDs) and
    socket.scope_before < data.date

handleNewClient = (socket) =>
    log.debug 'handleNewClient', socket.id

    # update the client refreshes status
    socket.emit 'refreshes.status', ImapReporter.summary()

    socket.on 'mark_ack', ImapReporter.acknowledge
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

