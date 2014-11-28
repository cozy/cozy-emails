AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'
url = window.location.origin
pathToSocketIO = "#{window.location.pathname}socket.io"
socket = io.connect url, path: pathToSocketIO

dispatchAs = (action) -> (content) ->
    AppDispatcher.handleServerAction
        type: action
        value: content

socket.on 'refresh.create', dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
socket.on 'refresh.update', dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
socket.on 'refresh.delete', dispatchAs ActionTypes.RECEIVE_REFRESH_DELETE

socket.on 'message.create', dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE
socket.on 'message.update', dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE
socket.on 'message.delete', dispatchAs ActionTypes.RECEIVE_MESSAGE_DELETE

exports.acknowledgeRefresh = (taskid) ->
    socket.emit 'mark_ack', taskid


exports.changeRealtimeScope = (boxid, date) ->
    socket.emit 'change_scope',
        mailboxID: boxid
        before: date
