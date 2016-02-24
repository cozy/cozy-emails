AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

socket = require('socket.io-client').connect window.location.origin,
    path: "#{window.location.pathname}socket.io"
    reconnectionDelayMax: 60000
    reconectionDelay: 2000
    reconnectionAttempts: 3

dispatchAs = (action) -> (content) ->
    AppDispatcher.handleServerAction
        type: action
        value: content

scope = {}
setServerScope = ->
    socket.emit 'change_scope', scope


# socket.on 'refresh.status', dispatchAs ActionTypes.RECEIVE_REFRESH_STATUS
# socket.on 'refresh.create', dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
# socket.on 'refresh.update', dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
# socket.on 'refresh.delete', dispatchAs ActionTypes.RECEIVE_REFRESH_DELETE

socket.on 'message.create', dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
socket.on 'message.update', dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
socket.on 'message.delete', dispatchAs ActionTypes.RECEIVE_MESSAGE_DELETE

socket.on 'mailbox.update', dispatchAs ActionTypes.RECEIVE_MAILBOX_UPDATE

socket.on 'connect', ->
    setServerScope()
socket.on 'reconnect', ->
    setServerScope()

socket.on 'refresh.notify', dispatchAs ActionTypes.RECEIVE_REFRESH_NOTIF

exports.changeRealtimeScope = (boxid, date) ->
    scope =
        mailboxID: boxid
        before: date
    setServerScope()
