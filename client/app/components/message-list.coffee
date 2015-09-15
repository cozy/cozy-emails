{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM
{MessageFlags, Tooltips} = require '../constants/app_constants'

RouterMixin           = require '../mixins/router_mixin'
TooltipRefresherMixin = require '../mixins/tooltip_refresher_mixin'
StoreWatchMixin       = require '../mixins/store_watch_mixin'

LayoutStore = require '../stores/layout_store'

classer      = React.addons.classSet
DomUtils     = require '../utils/dom_utils'
MessageUtils = require '../utils/message_utils'
SocketUtils  = require '../utils/socketio_utils'
colorhash    = require '../utils/colorhash'

ContactActionCreator = require '../actions/contact_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

Participants        = require './participant'
{Spinner, Progress} = require './basic_components'
ToolbarMessagesList = require './toolbar_messageslist'
MessageListBody = require './message-list-body'


module.exports = MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [
        RouterMixin,
        TooltipRefresherMixin
        StoreWatchMixin [LayoutStore]
    ]

    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))
        return should

    getInitialState: ->
        edited: false
        selected: {}
        allSelected: false

    getStateFromStores: ->
        fullscreen: LayoutStore.isPreviewFullscreen()

    componentWillReceiveProps: (props) ->
        if props.mailboxID isnt @props.mailboxID
            @setState allSelected: false, edited: false, selected: {}
        else
            selected = @state.selected
            # remove selected messages that are not in view anymore
            for id, isSelected of selected when not props.messages.get(id)
                delete selected[id]
            @setState selected: selected
            if Object.keys(selected).length is 0
                @setState allSelected: false, edited: false

    render: ->
        compact = @props.settings.get('listStyle') is 'compact'

        filterParams =
            accountID: @props.accountID
            mailboxID: @props.mailboxID
            query:     @props.query

        hasMore = @props.query.pageAfter isnt '-'
        # This allow to load next messages if needed after we remove messages
        # from this mailbox by moving or deleting them.
        # (if we delete all messages, the list is empty and listEmpty displayed)
        if hasMore
            afterAction = =>
                # ugly setTimeout to wait until localDelete occured
                setTimeout =>
                    listEnd = @refs.nextPage or @refs.listEnd or @refs.listEmpty
                    if listEnd? and
                       DomUtils.isVisible(listEnd.getDOMNode())
                        params = parameters: @props.query
                        LayoutActionCreator.showMessageList params
                , 100

        nextPage = =>
            LayoutActionCreator.showMessageList parameters: @props.query

        section
            key:               'messages-list'
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
                edited:               @state.edited
                selected:             @state.selected
                allSelected:          @state.allSelected
                displayConversations: @props.displayConversations
                toggleEdited:         @toggleEdited
                toggleAll:            @toggleAll
                afterAction:          afterAction
                queryParams:          @props.queryParams
                filter:               @props.filter

            # Progress
            Progress value: @props.refresh, max: 1

            # Message List
            if @props.messages.count() is 0
                if @props.fetching
                    p className: 'listFetching list-loading', t 'list fetching'
                else
                    p
                        className: 'listEmpty'
                        ref: 'listEmpty'
                        @props.emptyListMessage
            else
                div
                    className: 'main-content'
                    ref: 'scrollable',
                    MessageListBody
                        messages: @props.messages
                        settings: @props.settings
                        mailboxID: @props.mailboxID
                        messageID: @props.messageID
                        conversationID: @props.conversationID
                        conversationLengths: @props.conversationLengths
                        login: @props.login
                        edited: @state.edited
                        selected: @state.selected
                        allSelected: @state.allSelected
                        displayConversations: @props.displayConversations
                        isTrash: @props.isTrash
                        ref: 'listBody'
                        onSelect: (id, val) =>
                            selected = _.clone @state.selected
                            if val
                                selected[id] = val
                            else
                                delete selected[id]
                            if Object.keys(selected).length > 0
                                newState =
                                    edited: true
                                    selected: selected
                            else
                                newState =
                                    allSelected: false
                                    edited: false
                                    selected: {}
                            @setState newState

                    if hasMore
                        p className: 'text-center list-footer',
                            if @props.fetching
                                Spinner()
                            else
                                a
                                    className: 'more-messages'
                                    onClick: nextPage,
                                    ref: 'nextPage',
                                    t 'list next page'
                    else
                        p ref: 'listEnd', t 'list end'

    toggleEdited: ->
        if @state.edited
            @setState allSelected: false, edited: false, selected: {}
        else
            @setState edited: true

    toggleAll: ->
        if Object.keys(@state.selected).length > 0
            @setState allSelected: false, edited: false, selected: {}
        else
            selected = {}
            @props.messages.map (message, key) ->
                selected[key] = true
            .toJS()
            @setState allSelected: true, edited: true, selected: selected

    _loadNext: ->
        # load next message if last one is displayed (useful when navigating
        # with keyboard)
        lastMessage = @refs.listBody?.getDOMNode().lastElementChild
        if @refs.nextPage? and
           lastMessage? and
           DomUtils.isVisible(lastMessage)
            LayoutActionCreator.showMessageList parameters: @props.query

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

    componentDidUpdate: ->
        @_initScroll()
        @_handleRealtimeGrowth()

    componentWillUnmount: ->
        if @refs.scrollable?
            scrollable = @refs.scrollable.getDOMNode()
            scrollable.removeEventListener 'scroll', @_loadNext
            if @_checkNextInterval?
                window.clearInterval @_checkNextInterval

