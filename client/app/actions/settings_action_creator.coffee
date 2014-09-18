XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

SettingsStore = require '../stores/settings_store'

module.exports = SettingsActionCreator =

    edit: (inputValues) ->

        AppDispatcher.handleViewAction
            type: ActionTypes.SETTINGS_UPDATED
            value: inputValues


