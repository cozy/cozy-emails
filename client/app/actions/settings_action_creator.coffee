XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../libs/flux/dispatcher/dispatcher'
{ActionTypes} = require '../constants/app_constants'

SettingsStore = require '../stores/settings_store'

module.exports = SettingsActionCreator =

    edit: (inputValues) ->
        AppDispatcher.dispatch
            type: ActionTypes.SETTINGS_UPDATE_REQUEST
            value: inputValues

        XHRUtils.changeSettings inputValues, (error, values) ->
            if error
                AppDispatcher.dispatch
                    type: ActionTypes.SETTINGS_UPDATE_FAILURE
                    value: {error}
            else
                AppDispatcher.dispatch
                    type: ActionTypes.SETTINGS_UPDATE_SUCCESS
                    value: values
