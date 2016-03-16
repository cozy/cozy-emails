Immutable = require 'immutable'
React     = require 'react'
ReactDOM  = require 'react-dom'

{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM
{MessageFlags, Tooltips} = require '../constants/app_constants'

SelectionManager      = require '../mixins/selection_manager_mixin'

LayoutStore   = require '../stores/layout_store'
AccountStore  = require '../stores/account_store'
MessageStore  = require '../stores/message_store'
SettingsStore = require '../stores/settings_store'

DomUtils     = require '../utils/dom_utils'
MessageUtils = require '../utils/message_utils'
SocketUtils  = require '../utils/socketio_utils'
colorhash    = require '../utils/colorhash'

MessageActionCreator = require '../actions/message_action_creator'

{Spinner, Progress} = require('./basic_components').factories
MessageListLoader   = React.createFactory require './message-list-loader'
ToolbarMessagesList = React.createFactory require './toolbar_messageslist'
MessageListBody     = React.createFactory require './message-list-body'

CONVERSATION_DISABLED = ['trashMailbox','draftMailbox','junkMailbox']
{MessageFilter} = require '../constants/app_constants'


module.exports = MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [
        SelectionManager
    ]

    # FIXME : use getters instead
    # such as : MessagesListGetter.getState()
    getInitialState: ->
        @getStateFromStores()

    # FIXME : use getters instead
    # such as : MessagesListGetter.getState()
    componentWillReceiveProps: (nextProps={}) ->
        @setState @getStateFromStores()
        nextProps

    getStateFromStores: ->
        accountID = @props.accountID
        mailboxID = @props.mailboxID
        unless mailboxID
            return nextstate =
                mailboxes: @props.mailboxes
                messages: Immutable.Map()

        account   = AccountStore.getByID accountID
        role = AccountStore.getMailboxRole account, mailboxID
        settings = SettingsStore.get()
        mailbox   = account.get('mailboxes').get mailboxID
        messages  = MessageStore.getMessagesToDisplay mailboxID

        # select first conversation to allow navigation to start
        conversationLengths = MessageStore.getConversationsLength()
        conversationID = MessageStore.getCurrentConversationID()
        conversationID ?= messages.first()?.get 'conversationID'

        # don't display conversations in Trash and Draft folders
        mailboxes = AccountStore.getSelectedMailboxes(true)
        refresh = AccountStore.getMailboxRefresh @props.mailboxID

        return nextstate =
            messages             : messages
            messageID            : MessageStore.getCurrentID()
            conversationID       : conversationID
            login                : account?.get 'login'
            accountLabel         : account?.get 'label'
            mailboxes            : mailboxes
            mailbox              : mailboxes.get mailboxID
            settings             : settings
            fetching             : MessageStore.isFetching()
            refresh              : refresh
            isTrash              : role is 'trashMailbox'
            conversationLengths  : conversationLengths
            fullscreen           : LayoutStore.isPreviewFullscreen()

    # for SelectionManagerMixin
    getSelectables: (nil, state = {}) ->
        state = if Object.keys(state).length then state else @state
        state.messages.map (message) -> message.get('id')

    getEmptyListMessage: ->
        return @props.emptyListMessage if @props.emptyListMessage
        switch @props.queryParams.filter
            when MessageFilter.FLAGGED
                t 'no flagged message'
            when MessageFilter.UNSEEN
                t 'no unseen message'
            when MessageFilter.ALL
                t 'list empty'
            else
                t 'no filter message'

    render: ->
        mailbox = @state.mailboxes.get(@props.mailboxID)
        section
            key:               "messages-list-#{@props.mailboxID}"
            ref:               'list'
            'data-mailbox-id': @props.mailboxID
            className:         'messages-list panel'
            'aria-expanded':   not @state.fullscreen

            # Toolbar
            ToolbarMessagesList
                settings:             @state.settings
                accountID:            @props.accountID
                mailboxID:            @props.mailboxID
                mailboxes:            @state.mailboxes
                messages:             @state.messages
                edited:               @hasSelected()
                selected:             @getSelected()
                allSelected:          @allSelected()
                toggleAll:            @toggleAll
                queryParams:          @props.queryParams
                noFilters:            @props.noFilters

            if @state.refresh and not mailbox.get('lastSync')
                Progress value: 0, max: 1
                MessageListLoader()
            else
                Progress value: @state.refresh or 0, max: 1

            # Message List
            if @state.messages.size is 0
                if @state.fetching
                    p className: 'listFetching list-loading', t 'list fetching'
                else
                    p
                        className: 'list-empty'
                        ref: 'listEmpty'
                        @getEmptyListMessage()
            else
                div
                    className: 'main-content'
                    ref: 'scrollable',
                    MessageListBody
                        messages: @state.messages
                        settings: @state.settings
                        accountID: @props.accountID
                        mailboxID: @props.mailboxID
                        messageID: @state.messageID
                        conversationID: @state.conversationID
                        conversationLengths: @state.conversationLengths
                        accountLabel: @state.accountLabel
                        mailboxes: @state.mailboxes
                        login: @state.login
                        edited: @hasSelected()
                        selected: @getSelected()
                        allSelected: @allSelected()
                        isTrash: @state.isTrash
                        ref: 'listBody'
                        onSelect: @onMessageSelectionChange

                    @renderFooter()

    renderFooter: ->
        if @props.queryParams.hasNextPage
            p className: 'text-center list-footer',
                if @state.fetching
                    Spinner()
                else
                    a
                        className: 'more-messages'
                        onClick: @loadMoreMessage,
                        ref: 'nextPage',
                        t 'list next page'
        else
            p ref: 'listEnd', t 'list end'

    loadMoreMessage: ->
        MessageActionCreator.fetchMoreOfCurrentQuery()

    toggleAll: ->
        if @hasSelected() then @setNoneSelected()
        else @setAllSelected()

    onMessageSelectionChange: (id, val) ->
        if val then @addToSelected id
        else @removeFromSelected id

    _loadNext: ->
        # load next message if last one is displayed (useful when navigating
        # with keyboard)
        lastMessage = ReactDOM.findDOMNode(@refs.listBody)?.lastElementChild
        if @refs.nextPage? and lastMessage? and DomUtils.isVisible(lastMessage)
            @loadMoreMessage()

    _handleRealtimeGrowth: ->
        if @refs.listEnd? and not DomUtils.isVisible(@refs.listEnd)
            lastdate = @state.messages.last().get('date')
            SocketUtils.changeRealtimeScope @props.mailboxID, lastdate

    _initScroll: ->
        # listen to scroll events
        @refs.scrollable?.removeEventListener 'scroll', @_loadNext
        @refs.scrollable?.addEventListener 'scroll', @_loadNext

    componentDidMount: ->
        @_initScroll()

    componentDidUpdate: ->
        @_initScroll()
        @_handleRealtimeGrowth()

    componentWillUnmount: ->
        if @refs.scrollable?
            scrollable = @refs.scrollable
            scrollable.removeEventListener 'scroll', @_loadNext
            if @_checkNextInterval?
                window.clearInterval @_checkNextInterval
