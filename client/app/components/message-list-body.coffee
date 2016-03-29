_     = require 'underscore'

React = require 'react'

{ul} = React.DOM

MessageItem = React.createFactory require './message-list-item'

DomUtils = require '../utils/dom_utils'

SettingsStore = require '../stores/settings_store'
MessageStore = require '../stores/message_store'
RouterGetter = require '../getters/router'

module.exports = MessageListBody = React.createClass
    displayName: 'MessageListBody'

    render: ->
        ul className: 'list-unstyled', ref: 'messageList',
            @props.messages
                .mapEntries ([key, message]) =>
                    messageID = message.get 'id'
                    conversationID = message.get 'conversationID'

                    isSelected = -1 < @props.selection?.indexOf messageID

                    ["message-#{key}", MessageItem
                        key: 'conversation-' + conversationID
                        message: message
                        accountID: @props.accountID
                        mailboxID: @props.mailboxID
                        accountLabel: @props.accountLabel
                        conversationLengths: RouterGetter.getConversationLength messageID
                        settings: SettingsStore.get()
                        isSelected: isSelected
                        isActive: RouterGetter.isCurrentMessage messageID
                        login: @props.login
                        displayConversations: @props.displayConversations
                        ref: 'messageItem'
                    ]
                .toArray()
