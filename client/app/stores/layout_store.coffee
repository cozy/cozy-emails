Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'

class LayoutStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###


    # TODO: Use a constant for default value?
    _previewSize = 60

    _hidden = true

    _intentAvailable = false


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.TOASTS_SHOW, ->
            _hidden = false
            @emit 'change'

        handle ActionTypes.TOASTS_HIDE, ->
            _hidden = true
            @emit 'change'

        handle ActionTypes.INTENT_AVAILABLE, (avaibility) ->
            _intentAvailable = avaibility
            @emit 'change'


    ###
        Public API
    ###


    getPreviewSize: ->
        _previewSize


    isToastHidden: ->
        _hidden


    isIntentAvailable: ->
        _intentAvailable


module.exports = new LayoutStore()
