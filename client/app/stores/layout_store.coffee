Immutable = require 'immutable'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'

class LayoutStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###


    # TODO: Use a constant for default value?
    _previewSize = 60

    _shown = true

    _intentAvailable = false


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RESIZE_PREVIEW_PANE, (factor) ->
            if factor
                _previewSize += factor
                # set limits
                _previewSize = 20 if _previewSize < 20
                _previewSize = 80 if _previewSize > 80
            else
                _previewSize = 50
            @emit 'change'

        handle ActionTypes.REFRESH, ->
            @emit 'change'

        handle ActionTypes.TOASTS_SHOW, ->
            _shown = true
            @emit 'change'

        handle ActionTypes.TOASTS_HIDE, ->
            _shown = false
            @emit 'change'

        handle ActionTypes.INTENT_AVAILABLE, (avaibility) ->
            _intentAvailable = avaibility
            @emit 'change'


    ###
        Public API
    ###


    getPreviewSize: ->
        return _previewSize


    isShown: ->
        return _shown


    intentAvailable: ->
        return _intentAvailable


module.exports = new LayoutStore()
