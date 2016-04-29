React = require 'react'

{nav, div, button, a} = React.DOM
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

    render: ->
        nav className: 'toolbar toolbar-conversation btn-toolbar',
            ToolboxActions
                key                  : 'ToolboxActions-' + @props.conversationID
                mode                 : 'conversation'
                direction            : 'right'
                onConversationDelete : @onDelete
                onConversationMark   : @onMark
                onConversationMove   : @onMove

    onDelete: ->
        conversationID = @props.conversationID
        MessageActionCreator.delete {conversationID}


    onMark: (flag) ->
        conversationID = @props.conversationID
        MessageActionCreator.mark {conversationID}, flag


    onMove: (to) ->
        conversationID = @props.conversationID
        from = @props.mailboxID
        MessageActionCreator.move {conversationID}, from, to
