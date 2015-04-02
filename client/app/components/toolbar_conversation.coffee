{nav, div, button, a} = React.DOM

LayoutActionCreator = require '../actions/layout_action_creator'

RouterMixin = require '../mixins/router_mixin'

# Shortcut for button-like classes
cBtn = 'btn btn-default fa'

module.exports = React.createClass
    displayName: 'ToolbarConversation'

    mixins: [RouterMixin]

    propTypes:
        readability         : React.PropTypes.bool.isRequired
        nextMessageID       : React.PropTypes.string
        nextConversationID  : React.PropTypes.string
        prevMessageID       : React.PropTypes.string
        prevConversationID  : React.PropTypes.string
        settings            : React.PropTypes.object.isRequired


    getParams: (messageID, conversationID) ->
        if @props.settings.get 'displayConversation' and conversationID?
            action: 'conversation'
            parameters:
                messageID: messageID
                conversationID: conversationID
        else
            action: 'message'
            parameters:
                messageID: messageID


    render: ->
        nav className: 'toolbar toolbar-conversation btn-toolbar',
            div className: 'btn-group',
                @renderNav 'prev'
                @renderNav 'next'
            @renderFullscreen()


    renderNav: (direction) ->
        return unless @props["#{direction}MessageID"]?

        messageID = @props["#{direction}MessageID"]
        conversationID = @props["#{direction}ConversationID"]

        angle = if direction is 'prev' then 'left' else 'right'

        params = @getParams messageID, conversationID
        urlParams =
            direction: 'second'
            action: params.action
            parameters: params.parameters
        url =  @buildUrl urlParams

        a
            className: "btn btn-default fa fa-angle-#{angle}"
            onClick: => @redirect urlParams
            href: url


    renderFullscreen: ->
        if @props.readability
            button
                onClick: LayoutActionCreator.toggleFullscreen
                className: "clickable #{cBtn} fa-compress"
        else
            button
                onClick: LayoutActionCreator.toggleFullscreen
                className: "hidden-xs hidden-sm clickable #{cBtn} fa-expand"
