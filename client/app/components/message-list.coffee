Immutable = require 'immutable'
React     = require 'react'
ReactDOM  = require 'react-dom'

{div, section, p, a, button, ul, strong} = React.DOM
DomUtils = require '../utils/dom_utils'

RouterActionCreator = require '../actions/router_action_creator'

MessageItem         = React.createFactory require './message-list-item'

{Spinner, Progress} = require('./basic_components').factories
MessageListLoader   = React.createFactory require './message-list-loader'

RouterGetter = require '../getters/router'
SelectionGetter = require '../getters/selection'


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
        @_initScroll()


    componentDidUpdate: ->
        @_initScroll()


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
                    key: 'scrollable',
                    ref: 'scrollable',

                    ul
                        className: 'list-unstyled',
                        @props.messages.map(@renderItem).toArray()

                    if @props.hasNextPage
                        button
                            className: 'more-messages'
                            onClick: @loadMoreMessage,
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
            message             : message
            tags                : RouterGetter.getTags message
            conversationLengths : conversationLengths
            isSelected          : isSelected
            isActive            : isActive
            login               : RouterGetter.getLogin()
            mailboxID           : @props.mailboxID
            displayConversations: @props.displayConversations


    loadMoreMessage: ->
        RouterActionCreator.gotoNextPage()


    _initScroll: ->
        if not (scrollable = ReactDOM.findDOMNode @refs.scrollable) or scrollable.scrollTop
            return

        if (activeElement = scrollable.querySelector '[data-message-active="true"]')
            unless DomUtils.isVisible activeElement
                coords = activeElement.getBoundingClientRect()
                scrollable.scrollTop = coords.top - coords.height
