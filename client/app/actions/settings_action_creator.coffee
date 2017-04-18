XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

SettingsStore = require '../stores/settings_store'

module.exports = SettingsActionCreator =

    edit: (inputValues) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SETTINGS_UPDATE_REQUEST
            value: inputValues

        XHRUtils.changeSettings inputValues, (error, values) ->
            if error
                AppDispatcher.handleViewAction
                    type: ActionTypes.SETTINGS_UPDATE_FAILURE
                    value: {error}
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.SETTINGS_UPDATE_SUCCESS
                    value: values
