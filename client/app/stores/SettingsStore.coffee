Store = require '../libs/flux/store/Store'

{ActionTypes} = require '../constants/AppConstants'

class SettingsStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _settings =
        messagesPerPage : 5
        displayConversation: false

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
    get: -> return _settings

module.exports = new SettingsStore()
