ioclient = require('socket.io-client')

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'
{ActionTypes} = require '../constants/app_constants'


_scope  = {}
_socket = undefined


dispatchAs = (action) -> (content) ->
    AppDispatcher.dispatch
        type: action
        value: content


setServerScope = (params={}) ->
    _scope = params
    _socket.emit 'change_scope', _scope if _socket

module.exports.initRealtime = ->
    _socket = ioclient.connect window.location.origin,
        path: "#{window.location.pathname}socket.io"
        reconnectionDelayMax: 60000
        reconectionDelay: 2000
        reconnectionAttempts: 3

    _socket.on 'connect', -> setServerScope()
    _socket.on 'reconnect', -> setServerScope()

    # _socket.on 'refresh.status', dispatchAs ActionTypes.RECEIVE_REFRESH_STATUS
    # _socket.on 'refresh.create', dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
    # _socket.on 'refresh.update', dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
    # _socket.on 'refresh.delete', dispatchAs ActionTypes.RECEIVE_REFRESH_DELETE

    _socket.on 'message.create',
        dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
    _socket.on 'message.update',
        dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
    _socket.on 'message.delete',
        dispatchAs ActionTypes.RECEIVE_MESSAGE_DELETE
    _socket.on 'mailbox.update',
        dispatchAs ActionTypes.RECEIVE_MAILBOX_UPDATE
    _socket.on 'refresh.notify',
        dispatchAs ActionTypes.RECEIVE_REFRESH_NOTIF


module.exports.changeRealtimeScope = (args) ->
    {mailboxID, before} = args
    setServerScope {mailboxID, before}
