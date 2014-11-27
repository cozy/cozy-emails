AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'
url = window.location.origin
pathToSocketIO = "#{window.location.pathname}socket.io"
socket = io.connect url, path: pathToSocketIO

dispatchTaskUpdate = (task) ->
    AppDispatcher.handleServerAction
        type: ActionTypes.RECEIVE_REFRESH_UPDATE
        value: task

dispatchTaskDelete = (taskid) ->
    AppDispatcher.handleServerAction
        type: ActionTypes.RECEIVE_REFRESH_DELETE
        value: taskid

socket.on 'refresh.create', dispatchTaskUpdate
socket.on 'refresh.update', dispatchTaskUpdate
socket.on 'refresh.delete', dispatchTaskDelete

module.exports =

    acknowledgeRefresh: (taskid) ->
        socket.emit 'mark_ack', taskid
