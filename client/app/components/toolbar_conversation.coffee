React = require 'react'

{nav, div, button, a} = React.DOM
{Tooltips, FlagsConstants} = require '../constants/app_constants'
PropTypes                  = require '../libs/prop_types'

{Button, LinkButton} = require('./basic_components').factories
ToolboxActions       = React.createFactory require './toolbox_actions'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

Router = require '../mixins/router_mixin'

ToolboxActions = require './toolbox_actions'
{Button, LinkButton}  = require './basic_components'

module.exports = React.createClass
    displayName: 'ToolbarConversation'

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

    # FIXME : this should be in layout_action_creator
    gotoPreviousConversation: ->
        messageID = @props.prevMessageID or @props.nextMessageID
        Router.redirect {messageID}
        return

    # FIXME : this should be in layout_action_creator
    gotoNextConversation: ->
        messageID = @props.nextMessageID or @props.prevMessageID
        Router.redirect {messageID}
        return

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
        from = @propos.moveFromMailbox
        MessageActionCreator.move {conversationID}, from, to
