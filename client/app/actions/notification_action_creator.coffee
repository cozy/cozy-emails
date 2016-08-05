AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes} = require '../constants/app_constants'


NotificationActionCreator =

    taskDelete: (id) ->
        AppDispatcher.dispatch
            type: ActionTypes.CLICKED_TASK_OK
            value: id


module.exports = NotificationActionCreator
