XHRUtils = require '../utils/XHRUtils'
AppDispatcher = require '../AppDispatcher'
{ActionTypes} = require '../constants/AppConstants'

SettingsStore = require '../stores/SettingsStore'

module.exports = SettingsActionCreator =

    edit: (inputValues) ->

        AppDispatcher.handleViewAction
            type: ActionTypes.SETTINGS_UPDATED
            value: inputValues


    showSettings: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SETTINGS_SHOW
            value: null

