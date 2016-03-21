React = require 'react'

{nav, div, button, a} = React.DOM
{Tooltips, FlagsConstants} = require '../constants/app_constants'
PropTypes                  = require '../libs/prop_types'

{Button, LinkButton} = require('./basic_components').factories
ToolboxActions       = React.createFactory require './toolbox_actions'

LayoutActionCreator = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
RouterActionCreator = require '../actions/router_action_creator'

AccountStore = require '../stores/account_store'

module.exports = React.createClass
    displayName: 'ToolbarConversation'

    propTypes:
        conversationID      : React.PropTypes.string
        mailboxID           : React.PropTypes.string.isRequired
        fullscreen          : React.PropTypes.bool.isRequired

    render: ->
        console.log @props.previousMessageID, @props.nextMessageID
        nav className: 'toolbar toolbar-conversation btn-toolbar',

            ToolboxActions
                key                  : 'ToolboxActions-' + @props.conversationID
                mode                 : 'conversation'
                direction            : 'right'
                mailboxes            : AccountStore.getSelectedMailboxes()
                onConversationDelete : @onDelete
                onConversationMark   : @onMark
                onConversationMove   : @onMove

            div className: 'btn-group',
                if @props.previousMessageID?
                    LinkButton
                        icon: 'fa-chevron-left'
                        onClick: @gotoPreviousConversation
                        'aria-describedby': Tooltips.PREVIOUS_CONVERSATION
                        'data-tooltip-direction': 'left'

                if @props.nextMessageID?
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
        if (messageID = @props.previousMessageID)
            RouterActionCreator.navigate {messageID}

    gotoNextConversation: ->
        if (messageID = @props.nextMessageID)
            RouterActionCreator.navigate {messageID}

    onDelete: ->
        # Remove conversation
        conversationID = @props.conversationID

        MessageActionCreator.delete {conversationID}

        # Select previous conversation
        @gotoPreviousConversation()

    # FIXME : this should be in message_action_creator
    onMark: (flag) ->
        conversationID = @props.conversationID
        MessageActionCreator.mark {conversationID}, flag

    onMove: (to) ->
        conversationID = @props.conversationID
        from = @props.mailboxID
        MessageActionCreator.move {conversationID}, from, to
