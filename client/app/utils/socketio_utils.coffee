TaskStore = require '../stores/tasks_store'
AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'
url = window.location.origin
pathToSocketIO = "#{window.location.pathname}socket.io"
socket = io.connect url, resource: pathToSocketIO

dispatchTaskUpdate = (task) ->
    task.type = 'SERVER'
    AppDispatcher.handleServerAction
        type: ActionTypes.RECEIVE_TASK_UPDATE
        value: task

dispatchTaskDelete = (taskid) ->
    AppDispatcher.handleServerAction
        type: ActionTypes.RECEIVE_TASK_DELETE
        value: taskid

socket.on 'task.create', dispatchTaskUpdate
socket.on 'task.update', dispatchTaskUpdate
socket.on 'task.delete', dispatchTaskDelete

module.exports =

    acknowledgeTask: (taskid) ->
        socket.emit 'mark_ack', taskid
