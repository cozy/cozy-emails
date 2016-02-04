{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM
{MessageFlags, Tooltips} = require '../constants/app_constants'

RouterMixin           = require '../mixins/router_mixin'
TooltipRefresherMixin = require '../mixins/tooltip_refresher_mixin'
StoreWatchMixin       = require '../mixins/store_watch_mixin'
SelectionManager      = require '../mixins/selection_manager_mixin'
ShouldUpdate          = require '../mixins/should_update_mixin'

LayoutStore = require '../stores/layout_store'

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


module.exports = MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [
        SelectionManager
        ShouldUpdate.UnderscoreEqualitySlow
        RouterMixin,
        TooltipRefresherMixin
        StoreWatchMixin [LayoutStore]
    ]

    getStateFromStores: ->
        fullscreen: LayoutStore.isPreviewFullscreen()

    getSelectables: (props = @props) ->
        props.messages.keySeq()

    render: ->
        mailbox = @props.mailboxes.get(@props.mailboxID)
        section
            key:               "messages-list-#{@props.mailboxID}"
            ref:               'list'
            'data-mailbox-id': @props.mailboxID
            className:         'messages-list panel'
            'aria-expanded':   not @state.fullscreen

            # Toolbar
            ToolbarMessagesList
                settings:             @props.settings
                accountID:            @props.accountID
                mailboxID:            @props.mailboxID
                mailboxes:            @props.mailboxes
                messages:             @props.messages
                edited:               @hasSelected()
                selected:             @getSelected().toObject()
                allSelected:          @allSelected()
                displayConversations: @props.displayConversations
                toggleAll:            @toggleAll
                afterAction:          @afterMessageAction
                queryParams:          @props.queryParams
                noFilters:            @props.noFilters

            if @props.refresh and not mailbox.get('lastSync')
                Progress value: 0, max: 1
                MessageListLoader()
            else
                Progress value: @props.refresh, max: 1

            # Message List
            if @props.messages.count() is 0
                if @props.fetching
                    p className: 'listFetching list-loading', t 'list fetching'
                else
                    p
                        className: 'list-empty'
                        ref: 'listEmpty'
                        @props.emptyListMessage
            else
                div
                    className: 'main-content'
                    ref: 'scrollable',
                    MessageListBody
                        messages: @props.messages
                        settings: @props.settings
                        accountID: @props.accountID
                        mailboxID: @props.mailboxID
                        messageID: @props.messageID
                        conversationID: @props.conversationID
                        conversationLengths: @props.conversationLengths
                        accounts: @props.accounts
                        mailboxes: @props.mailboxes
                        login: @props.login
                        edited: @hasSelected()
                        selected: @getSelected().toObject()
                        allSelected: @allSelected()
                        displayConversations: @props.displayConversations
                        isTrash: @props.isTrash
                        ref: 'listBody'
                        onSelect: @onMessageSelectionChange

                    @renderFooter()

    renderFooter: ->
        if @props.canLoadMore
            p className: 'text-center list-footer',
                if @props.fetching
                    Spinner()
                else
                    a
                        className: 'more-messages'
                        onClick: @props.loadMoreMessage,
                        ref: 'nextPage',
                        t 'list next page'
        else
            p ref: 'listEnd', t 'list end'


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
                @props.loadMoreMessage()
        , 100

    _loadNext: ->
        # load next message if last one is displayed (useful when navigating
        # with keyboard)
        lastMessage = @refs.listBody?.getDOMNode().lastElementChild
        if @refs.nextPage? and lastMessage? and DomUtils.isVisible(lastMessage)
            @props.loadMoreMessage()

    _handleRealtimeGrowth: ->
        if @props.pageAfter isnt '-' and
           @refs.listEnd? and
           not DomUtils.isVisible(@refs.listEnd.getDOMNode())
            lastdate = @props.messages.last().get('date')
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
