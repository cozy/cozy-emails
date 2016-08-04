React     = require 'react'

{div, section, p, button, ul, strong} = React.DOM

MessageItem         = React.createFactory require './message-list-item'

{Spinner, Progress} = require('./basics/components').factories

RouterGetter = require '../getters/router'
LayoutGetter = require '../getters/layout'

module.exports = React.createClass
    displayName: 'MessageList'


    componentDidMount: ->
        return unless (el = @refs?['message-list-content'])?
        activeElement = el.querySelector '[data-message-active="true"]'
        if activeElement? and not LayoutGetter.isVisible activeElement
            el.scrollTop = activeElement.offsetTop - activeElement.offsetHeight

    render: ->
        # TODO: rediriger vers le message le plus proche
        # lorsque le message n'est plus dans la boite
        # ie. message non lus
        # console.log 'MESSAGE_LIST', @props.conversationID
        section
            'key'               : "messages-list-#{@props.mailboxID}"
            'ref'               : "messages-list"
            'data-mailbox-id'   : @props.mailboxID
            'className'         : 'messages-list panel'

            unless @props.lastSync?
                div className: 'mailbox-loading',
                    Spinner color: 'blue'
                    strong null, t 'emails are fetching'
                    p null, t 'thanks for patience'

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
        conversationLengths = RouterGetter.getConversationLength conversationID
        isActive = @props.conversationID is conversationID
        MessageItem
            key                 : "messageItem-#{messageID}-#{isActive}"
            messageID           : messageID
            flags               : message.get 'flags'
            message             : message
            conversationLengths : conversationLengths
            isActive            : isActive
            login               : RouterGetter.getLogin()
