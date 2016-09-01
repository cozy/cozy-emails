{ActionTypes} = require '../constants/app_constants'

NotificationActionCreator = (dispatch) ->

    taskDelete: (id) ->
        dispatch
            type: ActionTypes.CLICKED_TASK_OK
            value: id


module.exports = NotificationActionCreator
