ioclient = require 'socket.io-client'
{ActionTypes} = require '../constants/app_constants'

module.exports.initialize = (dispatcher) ->
    socket = ioclient.connect window.location.origin,
        path: "#{window.location.pathname}socket.io"
        reconnectionDelayMax: 60000
        reconectionDelay: 2000
        reconnectionAttempts: 3

    setServerScope = (params = {}) ->
        socket.emit 'change_scope', params

    socket.on 'connect', -> setServerScope()
    socket.on 'reconnect', -> setServerScope()

    module.exports.setServerScope = setServerScope

    socket2Action =
        'indexes.request':  ActionTypes.RECEIVE_INDEXES_REQUEST
        'indexes.complete': ActionTypes.RECEIVE_INDEXES_COMPLETE
        'refreshes.status': ActionTypes.RECEIVE_REFRESH_STATUS
        'refresh.update':   ActionTypes.RECEIVE_REFRESH_UPDATE
        'message.create':   ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
        'message.update':   ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
        'message.delete':   ActionTypes.RECEIVE_MESSAGE_DELETE
        'account.create':   ActionTypes.RECEIVE_ACCOUNT_CREATE
        'account.update':   ActionTypes.RECEIVE_ACCOUNT_UPDATE
        'mailbox.create':   ActionTypes.RECEIVE_MAILBOX_CREATE
        'mailbox.update':   ActionTypes.RECEIVE_MAILBOX_UPDATE
        'refresh.notify':   ActionTypes.RECEIVE_REFRESH_NOTIF

    Object.keys(socket2Action).forEach (eventname) ->
        socket.on eventname, (value) ->
            console.log("REALTIME", eventname, value)
            dispatcher.dispatch {type: socket2Action[eventname], value: value}

    undefined
