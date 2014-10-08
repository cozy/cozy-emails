XHRUtils = require '../utils/xhr_utils'
AppDispatcher = require '../app_dispatcher'
{ActionTypes} = require '../constants/app_constants'

SettingsStore = require '../stores/settings_store'
LayoutActionCreator = require './layout_action_creator'

module.exports = SettingsActionCreator =

    edit: (inputValues) ->
    	XHRUtils.changeSettings inputValues, (err, values) ->
    		if err
    			LayoutActionCreator.alertError t('error cannot save') + err

    		else
		        AppDispatcher.handleViewAction
		            type: ActionTypes.SETTINGS_UPDATED
		            value: values


