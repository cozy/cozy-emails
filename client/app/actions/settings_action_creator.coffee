XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

SettingsStore = require '../stores/settings_store'
NotificationActionsCreator = require '../actions/notification_action_creator'

module.exports = SettingsActionCreator =

    edit: (inputValues) ->
        XHRUtils.changeSettings inputValues, (err, values) ->
            if err
                NotificationActionsCreator.alertError t('settings save error') + err

            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.SETTINGS_UPDATED
                    value: values
