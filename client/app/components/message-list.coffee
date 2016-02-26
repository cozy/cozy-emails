{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM
{MessageFlags, Tooltips} = require '../constants/app_constants'

RouterMixin           = require '../mixins/router_mixin'
TooltipRefresherMixin = require '../mixins/tooltip_refresher_mixin'
StoreWatchMixin       = require '../mixins/store_watch_mixin'
SelectionManager      = require '../mixins/selection_manager_mixin'
ShouldUpdate          = require '../mixins/should_update_mixin'

LayoutStore = require '../stores/layout_store'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'
SettingsStore = require '../stores/settings_store'

classer      = React.addons.classSet
DomUtils     = require '../utils/dom_utils'
MessageUtils = require '../utils/message_utils'
SocketUtils  = require '../utils/socketio_utils'
colorhash    = require '../utils/colorhash'

ContactActionCreator = require '../actions/contact_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

MessageListLoader   = require './message-list-loader'
{Spinner, Progress} = require './basic_components'
ToolbarMessagesList = require './toolbar_messageslist'
MessageListBody = require './message-list-body'

CONVERSATION_DISABLED = ['trashMailbox','draftMailbox','junkMailbox']
{MessageFilter} = require '../constants/app_constants'

module.exports = MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [
        SelectionManager
        ShouldUpdate.UnderscoreEqualitySlow
        RouterMixin,
        TooltipRefresherMixin
        StoreWatchMixin [LayoutStore, AccountStore, MessageStore]
    ]

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
        displayConvs = !!(settings.get('displayConversations') and
        role not in CONVERSATION_DISABLED)
        mailbox   = account.get('mailboxes').get mailboxID
        messages  = MessageStore.getMessagesToDisplay mailboxID, displayConvs

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
            queryParams          : MessageStore.getQueryParams()
            fullscreen           : LayoutStore.isPreviewFullscreen()
            displayConversations : displayConvs

    # for SelectionManagerMixin
    getSelectables: (props = @props, state = @state) ->
        state.messages.keySeq()

    getEmptyListMessage: ->
        return @props.emptyListMessage if @props.emptyListMessage
        switch @state.queryParams.filter
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
                selected:             @getSelected().toObject()
                allSelected:          @allSelected()
                displayConversations: @state.displayConversations
                toggleAll:            @toggleAll
                afterAction:          @afterMessageAction
                queryParams:          @state.queryParams
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
                        selected: @getSelected().toObject()
                        allSelected: @allSelected()
                        displayConversations: @state.displayConversations
                        isTrash: @state.isTrash
                        ref: 'listBody'
                        onSelect: @onMessageSelectionChange

                    @renderFooter()

    renderFooter: ->
        if @state.queryParams.hasNextPage
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

    afterMessageAction: ->
        # ugly setTimeout to wait until localDelete occured
        setTimeout =>
            listEnd = @refs.nextPage or @refs.listEnd or @refs.listEmpty
            if listEnd? and DomUtils.isVisible(listEnd.getDOMNode())
                @loadMoreMessage()
        , 100

    _loadNext: ->
        # load next message if last one is displayed (useful when navigating
        # with keyboard)
        lastMessage = @refs.listBody?.getDOMNode().lastElementChild
        if @refs.nextPage? and lastMessage? and DomUtils.isVisible(lastMessage)
            @loadMoreMessage()

    _handleRealtimeGrowth: ->
        if @refs.listEnd? and not DomUtils.isVisible(@refs.listEnd.getDOMNode())
            lastdate = @state.messages.last().get('date')
            SocketUtils.changeRealtimeScope @props.mailboxID, lastdate

    _initScroll: ->
        if not @refs.nextPage?
            return

        # listen to scroll events
        if @refs.scrollable?
            scrollable = @refs.scrollable.getDOMNode()
            setTimeout =>
                scrollable.removeEventListener 'scroll', @_loadNext
                scrollable.addEventListener 'scroll', @_loadNext
                @_loadNext()
                # a lot of event can make the "more messages" label visible,
                # so we check every few seconds
                if not @_checkNextInterval?
                    @_checkNextInterval = window.setInterval @_loadNext, 10000
            , 0

    componentDidMount: ->
        @_initScroll()
        setTimeout MessageActionCreator.fetchMoreOfCurrentQuery, 1

    componentDidUpdate: ->
        @_initScroll()
        @_handleRealtimeGrowth()

    componentWillUnmount: ->
        if @refs.scrollable?
            scrollable = @refs.scrollable.getDOMNode()
            scrollable.removeEventListener 'scroll', @_loadNext
            if @_checkNextInterval?
                window.clearInterval @_checkNextInterval
