React = require 'react'

{nav, div, button, a} = React.DOM
{Tooltips, FlagsConstants} = require '../constants/app_constants'
PropTypes                  = require '../libs/prop_types'

{Button, LinkButton} = require('./basic_components').factories
ToolboxActions       = React.createFactory require './toolbox_actions'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

RouterMixin = require '../mixins/router_mixin'


module.exports = React.createClass
    displayName: 'ToolbarConversation'

    mixins: [RouterMixin]

    propTypes:
        conversation        : PropTypes.object.isRequired
        conversationID      : React.PropTypes.string
        moveFromMailbox     : React.PropTypes.string.isRequired
        moveToMailboxes     : PropTypes.mapOfMailbox
        nextMessageID       : React.PropTypes.string
        nextConversationID  : React.PropTypes.string
        prevMessageID       : React.PropTypes.string
        prevConversationID  : React.PropTypes.string
        fullscreen          : React.PropTypes.bool.isRequired

    render: ->
        nav className: 'toolbar toolbar-conversation btn-toolbar',

            ToolboxActions
                mode                 : 'conversation'
                direction            : 'right'
                inConversation       : true
                mailboxes            : @props.moveToMailboxes
                onConversationDelete : @onDelete
                onConversationMark   : @onMark
                onConversationMove   : @onMove

            div className: 'btn-group',
                if @props.prevConversationID
                    LinkButton
                        icon: 'fa-chevron-left'
                        onClick: @gotoPreviousConversation
                        'aria-describedby': Tooltips.PREVIOUS_CONVERSATION
                        'data-tooltip-direction': 'left'

                if @props.nextConversationID
                    LinkButton
                        icon: 'fa-chevron-right'
                        onClick: @gotoNextConversation
                        'aria-describedby': Tooltips.NEXT_CONVERSATION
                        'data-tooltip-direction': 'left'

            Button
                icon: if @props.fullscreen then 'fa-compress' else 'fa-expand'
                onClick: LayoutActionCreator.toggleFullscreen
                className: "clickable fullscreen"

    gotoPreviousConversation: ->
        if (messageID = @props.prevMessageID)
            conversationID = @props.prevConversationID
        else
            # Current Message is the last of the list
            messageID = @props.nextMessageID
            conversationID = @props.nextConversationID
        @goto messageID, conversationID
        return

    gotoNextConversation: ->
        if (messageID = @props.nextMessageID)
            conversationID = @props.nextConversationID
        else
            # Current Message is the first of the list
            messageID = @props.prevMessageID
            conversationID = @props.prevConversationID
        @goto messageID, conversationID
        return

    goto: (messageID, conversationID) ->
        if not messageID or not conversationID
            @redirect @buildClosePanelUrl 'second'
            return

        parameters = @getUrlParams messageID, conversationID
        @redirect parameters

    onDelete: ->
        # Remove conversation
        conversationID = @props.conversationID

        MessageActionCreator.delete {conversationID}

        # Select previous conversation
        @gotoPreviousConversation()

    onMark: (flag) ->
        conversationID = @props.conversationID
        MessageActionCreator.mark {conversationID}, flag

    onMove: (to) ->
        conversationID = @props.conversationID
        from = @propos.moveFromMailbox
        MessageActionCreator.move {conversationID}, from, to

    getUrlParams: (messageID, conversationID) ->
        direction: 'second'
        action: 'conversation'
        parameters:
            messageID: messageID
            conversationID: conversationID
