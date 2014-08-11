module.exports = LayoutStore = Fluxxor.createStore

    actions:
        'SHOW_MENU_RESPONSIVE': '_shownResponsiveMenu'
        'HIDE_MENU_RESPONSIVE': '_hideResponsiveMenu'

    initialize: ->
        @responsiveMenuShown = false

    _shownResponsiveMenu: ->
        @responsiveMenuShown = true
        @emit 'change'

    _hideResponsiveMenu: ->
        @responsiveMenuShown = false
        @emit 'change'

    isMenuShown: -> return @responsiveMenuShown

