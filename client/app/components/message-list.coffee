Immutable = require 'immutable'
React     = require 'react'
ReactDOM  = require 'react-dom'

{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM

SelectionGetter = require '../getters/selection'
RouterGetter = require '../getters/router'

# React Mixins
SettingsStore        = require '../stores/settings_store'
MessageStore        = require '../stores/message_store'
LayoutStore          = require '../stores/layout_store'
RouterStore = require '../stores/router_store'

SelectionStore       = require '../stores/selection_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'

DomUtils     = require '../utils/dom_utils'

RouterActionCreator = require '../actions/router_action_creator'

{Spinner, Progress} = require('./basic_components').factories
MessageListLoader   = React.createFactory require './message-list-loader'
ToolbarMessagesList = React.createFactory require './toolbar_messageslist'
MessageListBody     = React.createFactory require './message-list-body'

{MessageFilter} = require '../constants/app_constants'


module.exports = MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [
        StoreWatchMixin [SelectionStore, MessageStore]
    ]

    # FIXME : use getters instead
    # such as : MessagesListGetter.getState()
    getInitialState: ->
        @getStateFromStores()

    componentWillReceiveProps: (nextProps={}) ->
        @setState @getStateFromStores()
        nextProps

    componentDidMount: ->
        @_initScroll()

    componentDidUpdate: ->
        @_initScroll()

    getStateFromStores: ->
        messages = RouterGetter.getMessagesToDisplay @props.mailboxID
        selection = SelectionGetter.getProps messages
        nextstate = _.extend selection,
            messages    : messages
            hasNextPage : !!RouterGetter.getNextURL()
        return nextstate

    render: ->
        console.log 'MESSAGE_LIST', @state.selection
        section
            'key'               : "messages-list-#{@props.mailboxID}"
            'ref'               : 'list'
            'data-mailbox-id'   : @props.mailboxID
            'className'         : 'messages-list panel'

            # Toolbar
            ToolbarMessagesList
                ref: 'messageList-toolbar'
                key: 'messageList-toolbar-' + @state.selection?.length
                settings: SettingsStore.get()
                accountID: @props.accountID
                mailboxID: @props.mailboxID
                messages: @state.messages
                selection: @state.selection
                isAllSelected: @state.isAllSelected

            # Message List
            if @state.isLoading?
                p className: 'listFetching list-loading', t 'list fetching'
            else
                unless @state.messages.size
                    p
                        className: 'list-empty'
                        ref: 'listEmpty'
                        RouterGetter.getEmptyMessage()
                else
                    div
                        className: 'main-content'
                        ref: 'scrollable',

                        MessageListBody
                            messages: @state.messages
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
        RouterActionCreator.getNextPage()

    _loadNext: ->
        # load next message if last one is displayed (useful when navigating
        # with keyboard)
        lastMessage = ReactDOM.findDOMNode(@refs.listBody)?.lastElementChild
        if lastMessage? and DomUtils.isVisible(lastMessage)
            @loadMoreMessage()

    _initScroll: ->
        if not (scrollable = ReactDOM.findDOMNode @refs.scrollable) or scrollable.scrollTop
            return

        activeElement = scrollable.querySelector '[data-message-active="true"]'
        if @props.messageID and not activeElement
            console.log 'LOAD_MORE_MESSAGES'
            # @loadMoreMessage()
            return

        if activeElement
            scrollTop = activeElement.offsetTop - activeElement.getBoundingClientRect().height
            scrollable.scrollTop = scrollTop
