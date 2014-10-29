XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

SettingsStore = require '../stores/settings_store'
LayoutActionCreator = require './layout_action_creator'

refreshInterval = null

module.exports = SettingsActionCreator =

    edit: (inputValues) ->
        XHRUtils.changeSettings inputValues, (err, values) ->
            if err
                LayoutActionCreator.alertError t('error cannot save') + err

            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.SETTINGS_UPDATED
                    value: values

    setRefresh: (value) ->
        if value? and value >= 1
            if refreshInterval?
                window.clearInterval refreshInterval
            refreshInterval = window.setInterval ->
                LayoutActionCreator.refreshMessages()
            , value * 60000
