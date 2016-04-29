Immutable = require 'immutable'
React     = require 'react'
ReactDOM  = require 'react-dom'

{div, section, p, a} = React.DOM
DomUtils = require '../utils/dom_utils'

SelectionGetter = require '../getters/selection'
RouterGetter = require '../getters/router'

# React Mixins
MessageStore        = require '../stores/message_store'
SettingsStore       = require '../stores/settings_store'
SelectionStore      = require '../stores/selection_store'
StoreWatchMixin     = require '../mixins/store_watch_mixin'

RouterActionCreator = require '../actions/router_action_creator'

ToolbarMessagesList = React.createFactory require './toolbar_messageslist'
MessageListBody     = React.createFactory require './message-list-body'

module.exports = MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [
        StoreWatchMixin [SelectionStore, MessageStore]
    ]

    componentDidMount: ->
        @_initScroll()

    componentDidUpdate: ->
        @_initScroll()

    getStateFromStores: (props={}) ->
        messages = props.messages or @props.messages
        return {
            isAllSelected   : SelectionGetter.isAllSelected()
            selection       : SelectionGetter.getSelection messages
            hasNextPage     : RouterGetter.hasNextPage()
        }

    render: ->
        section
            'key'               : "messages-list-#{@props.mailboxID}"
            'ref'               : 'list'
            'data-mailbox-id'   : @props.mailboxID
            'className'         : 'messages-list panel'

            # Toolbar
            ToolbarMessagesList
                ref: 'messageList-toolbar'
                key: 'messageList-toolbar-' + @state.selection?.length
                accountID: @props.accountID
                mailboxID: @props.mailboxID
                messages: @props.messages
                selection: @state.selection
                isAllSelected: @state.isAllSelected

            # Message List
            unless @props.messages?.size
                p
                    className: 'list-empty'
                    ref: 'listEmpty'
                    RouterGetter.getEmptyMessage()
            else
                div
                    className: 'main-content'
                    ref: 'scrollable',

                    MessageListBody
                        messages: @props.messages
                        accountID: @props.accountID
                        mailboxID: @props.mailboxID
                        selection: @state.selection
                        ref: 'listBody'

                    if @state.hasNextPage
                        a
                            className: 'more-messages'
                            onClick: @loadMoreMessage,
                            ref: 'nextPage',
                            t 'list next page'
                    else
                        p ref: 'listEnd', t 'list end'

    loadMoreMessage: ->
        RouterActionCreator.gotoNextPage()

    _initScroll: ->
        if not (scrollable = ReactDOM.findDOMNode @refs.scrollable) or scrollable.scrollTop
            return

        if (activeElement = scrollable.querySelector '[data-message-active="true"]')
            unless DomUtils.isVisible activeElement
                coords = activeElement.getBoundingClientRect()
                scrollable.scrollTop = coords.top - coords.height
