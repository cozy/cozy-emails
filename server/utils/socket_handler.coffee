ImapReporter = require '../imap/reporter'
log = require('../utils/logging')('sockethandler')
ioServer = require 'socket.io'
Mailbox = require '../models/mailbox'
stream = require 'stream'
_ = require 'lodash'

io = null
sockets = []

SocketHandler = exports

SocketHandler.setup = (app, server) ->
    io = ioServer server
    ImapReporter.setIOReference io
    io.on 'connection', handleNewClient


SocketHandler.notify = (type, data, olddata) ->
    log.debug "notify", type
    if type in ['message.update', 'message.create']
        # we cant just spam the client with all
        # message events, check if the message is in
        # client current's view
        for socket in sockets
            if inScope(socket, data) or (olddata and inScope(socket, olddata))
                log.debug "notify2", type
                socket.emit type, data

    else if type is 'mailbox.update'
        # include the mailbox counts
        Mailbox.getCounts data.id, (err, results) ->
            if results[data.id]
                {total, unread, recent} = results[data.id]
                data.nbTotal  = total
                data.nbUnread = unread
                data.nbRecent = recent
            io?.emit type, data

    else
        io?.emit type, data


_toClientObject = (docType, raw, callback) ->
    if docType is 'message'
        callback null, raw.toClientObject()
    else if docType is 'account'
        raw.toClientObject (err, clientRaw) ->
             if err then callback null, raw
             else callback null, clientRaw
    else
        callback null, raw.toObject()

_onObjectCreated = (docType, created) ->
    _toClientObject docType, created, ->
        SocketHandler.notify "#{docType}.create", created

_onObjectUpdated = (docType, updated, old) ->
    _toClientObject docType, updated, ->
        SocketHandler.notify "#{docType}.update", updated, old

_onObjectDeleted = (docType, id, old) ->
    SocketHandler.notify "#{docType}.delete", id, old

# using DS events imply one more query for each update
# instead we monkeypatch JDB
SocketHandler.wrapModel = (Model, docType) ->

    _oldCreate = Model.create
    Model.create = (data, callback) ->
        _oldCreate.call Model, data, (err, created) ->
            _onObjectCreated docType, created unless err
            callback err, created

    _oldUpdateAttributes = Model::updateAttributes
    Model::updateAttributes = (data, callback) ->
        old = _.cloneDeep @toObject()
        _oldUpdateAttributes.call this, data, (err, updated) ->
            _onObjectUpdated docType, updated, old unless err
            callback err, updated

    _oldDestroy = Model::destroy
    Model::destroy = (callback) ->
        old = @toObject()
        id = old.id
        _oldDestroy.call this, (err) ->
            unless err
                SocketHandler.notify "#{docType}.delete", id, old
            callback err

inScope = (socket, data) ->
    log.info "inscope", socket.scope_mailboxID, Object.keys data.mailboxIDs
    (socket.scope_mailboxID in Object.keys data.mailboxIDs) and
    socket.scope_before < data.date

handleNewClient = (socket) ->
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

