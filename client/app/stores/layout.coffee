module.exports = LayoutStore = Fluxxor.createStore

    actions:
        'SHOW_ROUTE': 'onRoute'

    initialize: ->
        @layout =
            leftPanel:
                action: 'mailbox.emails'
                parameter: null
            rightPanel: null

    onRoute: (args) ->

        {name, leftPanelInfo, rightPanelInfo} = args

        @layout =
            leftPanel:
                action: name
                parameter: leftPanelInfo # holds the parameter value
            rightPanel: rightPanelInfo

        @emit 'change'

    getState: -> return @layout

    isFullWidth: -> return not @layout.rightPanel?
