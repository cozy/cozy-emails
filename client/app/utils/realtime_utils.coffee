ioclient = require('socket.io-client')

AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'


scope  = {}
socket = undefined


dispatchAs = (action) -> (content) ->
    AppDispatcher.dispatch
        type: action
        value: content


setServerScope = ->
    socket.emit 'change_scope', scope


module.exports.initRealtime = ->
    socket = ioclient.connect window.location.origin,
        path: "#{window.location.pathname}socket.io"
        reconnectionDelayMax: 60000
        reconectionDelay: 2000
        reconnectionAttempts: 3

    socket.on 'refresh.status', dispatchAs ActionTypes.RECEIVE_REFRESH_STATUS
    socket.on 'refresh.create', dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
    socket.on 'refresh.update', dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
    socket.on 'refresh.delete', dispatchAs ActionTypes.RECEIVE_REFRESH_DELETE

    socket.on 'message.create',
        dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
    socket.on 'message.update',
        dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
    socket.on 'message.delete',
        dispatchAs ActionTypes.RECEIVE_MESSAGE_DELETE
    socket.on 'mailbox.update',
        dispatchAs ActionTypes.RECEIVE_MAILBOX_UPDATE
    socket.on 'connect',
        setServerScope
    socket.on 'reconnect',
        setServerScope
    socket.on 'refresh.notify',
        dispatchAs ActionTypes.RECEIVE_REFRESH_NOTIF


module.exports.changeRealtimeScope = (boxid, date) ->
    scope =
        mailboxID: boxid
        before: date
    setServerScope()
