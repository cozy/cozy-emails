Store = require '../libs/flux/store/Store'

{ActionTypes} = require '../constants/AppConstants'

class SettingsStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _settings = Immutable.Map
        messagesPerPage: 5
        displayConversation: false
        composeInHTML: true

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.SETTINGS_UPDATED, (settings) ->
            _settings = Immutable.Map settings
            @emit 'change'


    ###
        Public API
    ###
    get: (settingName = null) ->
        if settingName?
            return _settings.get settingName
        else
            return _settings

module.exports = new SettingsStore()
