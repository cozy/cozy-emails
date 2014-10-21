Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'

class LayoutStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _responsiveMenuShown = false
    _alert =
        level: null
        message: null


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.SHOW_MENU_RESPONSIVE, ->
            _responsiveMenuShown = true
            @emit 'change'

        handle ActionTypes.HIDE_MENU_RESPONSIVE, ->
            _responsiveMenuShown = false
            @emit 'change'

        handle ActionTypes.DISPLAY_ALERT, (value) ->
            _alert.level   = value.level
            _alert.message = value.message
            @emit 'change'

        handle ActionTypes.REFRESH, ->
            @emit 'change'

    ###
        Public API
    ###
    isMenuShown: -> return _responsiveMenuShown

    getAlert: -> return _alert

module.exports = new LayoutStore()
