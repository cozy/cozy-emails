Immutable = require 'immutable'
React     = require 'react'
ReactDOM  = require 'react-dom'

{div, section, p, a, button, ul, strong} = React.DOM

RouterActionCreator = require '../actions/router_action_creator'

MessageItem         = React.createFactory require './message-list-item'

{Spinner, Progress} = require('./basic_components').factories
MessageListLoader   = React.createFactory require './message-list-loader'

RouterGetter = require '../getters/router'
SelectionGetter = require '../getters/selection'
LayoutGetter = require '../getters/layout'


_scrollToActive = ->
    return unless (el = @refs?['message-list-content'])?
    activeElement = el.querySelector '[data-message-active="true"]'
    if activeElement? and not LayoutGetter.isVisible activeElement
        el.scrollTop = activeElement.offsetTop - activeElement.offsetHeight


_loadMoreMessage = ->
    RouterActionCreator.gotoNextPage()


module.exports = React.createClass
    displayName: 'MessageList'


    getInitialState: ->
        displayProgress = true
        {displayProgress}


    componentWillReceiveProps: ->
        displayProgress = RouterGetter.isMailboxLoading()
        if displayProgress isnt @state?.displayProgress
            @setState {displayProgress}


    componentDidMount: ->
        _scrollToActive.call @


    componentDidUpdate: ->
        _scrollToActive.call @


    render: ->
        unless @props.isMailbox
            return div className: 'mailbox-loading',
                Spinner color: 'blue'
                strong null, t 'emails are fetching'
                p null, t 'thanks for patience'


        section
            'key'               : "messages-list-#{@props.mailboxID}"
            'ref'               : "messages-list"
            'data-mailbox-id'   : @props.mailboxID
            'className'         : 'messages-list panel'

            # Progress Bar of mailbox refresh
            if @state?.displayProgress
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
                            onClick: _loadMoreMessage,
                            ref: 'nextPage',
                            t 'list next page'
                    else
                        p ref: 'listEnd', t 'list end'


    renderItem: (message) ->
        messageID = message.get 'id'
        conversationID = message.get 'conversationID'
        isSelected = -1 < @props.selection?.indexOf messageID
        conversationLengths = RouterGetter.getConversationLength {conversationID}
        isActive = RouterGetter.isCurrentConversation conversationID
        MessageItem
            key                 : "messageItem-#{messageID}"
            messageID           : messageID
            conversationID      : conversationID
            message             : message
            tags                : RouterGetter.getTags message
            conversationLengths : conversationLengths
            isSelected          : isSelected
            isActive            : isActive
            login               : RouterGetter.getLogin()
            mailboxID           : @props.mailboxID
            displayConversations: @props.displayConversations
