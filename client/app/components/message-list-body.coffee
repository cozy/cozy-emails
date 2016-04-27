_     = require 'underscore'

React = require 'react'

{ul} = React.DOM

MessageItem = React.createFactory require './message-list-item'

DomUtils = require '../utils/dom_utils'

SettingsStore = require '../stores/settings_store'
RouterGetter = require '../getters/router'

module.exports = MessageListBody = React.createClass
    displayName: 'MessageListBody'


    renderItem: (message) ->
        messageID = message.get 'id'
        conversationID = message.get 'conversationID'
        MessageItem
            key: "conversation-#{messageID}"
            message: message
            mailboxID: @props.mailboxID
            conversationLengths: RouterGetter.getConversationLength {conversationID}
            isCompact: SettingsStore.get('listStyle') is 'compact'
            isSelected: -1 < @props.selection?.indexOf messageID
            isActive: RouterGetter.isCurrentConversation conversationID
            login: RouterGetter.getLogin()
            displayConversations: @props.displayConversations
            tags:  RouterGetter.getTags message


    render: ->
        ul
            className: 'list-unstyled'
            ref: 'messageList',
                @props.messages.map(@renderItem).toArray()
