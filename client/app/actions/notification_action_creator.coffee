AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

NotificationStore  = require '../stores/notification_store'

{ActionTypes, AlertLevel} = require '../constants/app_constants'

NotificationActionCreator =

    alert: (message) ->
        NotificationStore.notify message,
            level: AlertLevel.INFO
            autoclose: true

    alertSuccess: (message) ->
        NotificationStore.notify message,
            level: AlertLevel.SUCCESS
            autoclose: true

    alertWarning: (message) ->
        NotificationStore.notify message,
            level: AlertLevel.WARNING
            autoclose: true

    alertError: (message) ->
        NotificationStore.notify message,
            level: AlertLevel.ERROR
            autoclose: true

    taskDelete: (id) ->
        AppDispatcher.dispatch
            type: ActionTypes.RECEIVE_TASK_DELETE
            value: id


module.exports = NotificationActionCreator
