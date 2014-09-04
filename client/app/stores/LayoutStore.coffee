Store = require '../libs/flux/store/Store'

{ActionTypes} = require '../constants/AppConstants'

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


    ###
        Public API
    ###
    isMenuShown: -> return _responsiveMenuShown

    displayAlert: (level, message) ->
        _alert.level   = level
        _alert.message = message
        @emit 'change'

    getAlert: -> return _alert

module.exports = new LayoutStore()
