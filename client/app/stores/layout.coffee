module.exports = LayoutStore = Fluxxor.createStore

    actions:
        'SHOW_PANEL': '_showPanel'
        'HIDE_PANEL': '_hidePanel'

    initialize: ->
        @layout =
            leftPanel:
                action: 'mailbox.emails'
                parameter: null
            rightPanel: null

    _showPanel: (payload) ->
        {panelInfo, direction} = payload

        if direction is 'left'
            @layout.leftPanel = panelInfo
        else
            @layout.rightPanel = panelInfo

        @emit 'change'

    _hidePanel: (direction) ->

        # closing the left panel equals expanding the right panel
        if direction is 'left'
            @layout.leftPanel = @layout.rightPanel
            @layout.rightPanel = null
        else
            @layout.rightPanel = null

        @emit 'change'

    getState: -> return @layout

    isFullWidth: -> return not @layout.rightPanel?
