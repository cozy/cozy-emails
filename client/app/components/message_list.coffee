React     = require 'react'
Immutable = require 'immutable'

{div, section, p, button, ul} = React.DOM

MessageItem         = React.createFactory require './message_list_item'
MessageListLoader   = React.createFactory require './message_list_loader'

{Progress} = require('./basics/components').factories

isVisible = require '../libs/is_visible'

module.exports = React.createClass
    displayName: 'MessageList'

    propTypes:
        conversationID: React.PropTypes.string
        conversationsLengths: React.PropTypes.instanceOf(Immutable.Map)
        mailboxID: React.PropTypes.string.isRequired
        lastSync: React.PropTypes.string.isRequired
        isLoading: React.PropTypes.bool.isRequired
        messages: React.PropTypes.instanceOf(Immutable.Map)
        emptyMessages: React.PropTypes.string.isRequired
        hasNextPage: React.PropTypes.bool.isRequired
        onLoadMore: React.PropTypes.func.isRequired
        login: React.PropTypes.string.isRequired
        contacts: React.PropTypes.instanceOf(Immutable.Map)


    componentDidMount: ->
        return unless (el = @refs?['message-list-content'])?
        activeElement = el.querySelector '[data-message-active="true"]'
        if activeElement? and not isVisible activeElement
            el.scrollTop = activeElement.offsetTop - activeElement.offsetHeight

    render: ->
        # TODO: rediriger vers le message le plus proche
        # lorsque le message n'est plus dans la boite
        # ie. message non lus
        section
            'key'               : "messages-list-#{@props.mailboxID}"
            'ref'               : "messages-list"
            'data-mailbox-id'   : @props.mailboxID
            'className'         : 'messages-list panel'

            unless @props.lastSync?
                MessageListLoader()

            # Progress Bar of mailbox refresh
            if @props.isLoading
                Progress
                    value: 0
                    max: 1

            # Message List
            unless @props.messages?.size
                p
                    className: 'list-empty'
                    ref: 'listEmpty'
                    @props.emptyMessages
            else
                div
                    className: 'main-content'
                    ref: 'message-list-content',

                    ul
                        className: 'list-unstyled',
                        @props.messages.map(@renderItem).toArray()

                    if @props.hasNextPage
                        button
                            className: 'more-messages'
                            onClick: @props.onLoadMore,
                            ref: 'nextPage',
                            t 'list next page'
                    else
                        p ref: 'listEnd', t 'list end'


    renderItem: (message) ->
        messageID = message.get 'id'
        conversationID = message.get 'conversationID'
        conversationLength = @props.conversationsLengths
                            .get(conversationID) or 1
        isActive = @props.conversationID is conversationID
        MessageItem
            key                 : "messageItem-#{messageID}-#{isActive}"
            messageID           : messageID
            flags               : message.get 'flags'
            message             : message
            conversationLength  : conversationLength
            isActive            : isActive
            login               : @props.login
            gotoConversation    : @props.gotoConversation
            contacts            : @props.contacts
