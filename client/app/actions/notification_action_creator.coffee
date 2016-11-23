AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes} = require '../constants/app_constants'


NotificationActionCreator =

    taskDelete: (id) ->
        AppDispatcher.dispatch
            type: ActionTypes.RECEIVE_TASK_DELETE
            value: id


module.exports = NotificationActionCreator
