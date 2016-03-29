Immutable = require 'immutable'
React     = require 'react'
ReactDOM  = require 'react-dom'

{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM

SelectionGetters = require '../getters/selection'
RouterGetter = require '../getters/router'

# React Mixins
AccountStore         = require '../stores/account_store'
SettingsStore        = require '../stores/settings_store'
LayoutStore          = require '../stores/layout_store'

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
        StoreWatchMixin [SelectionStore, LayoutStore]
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

    componentDidMount: ->
        @_initScroll()

    componentDidUpdate: ->
        @_resetScroll()
        @_initScroll()

    componentWillUnmount: ->
        @_resetScroll()
        RouterActionCreator.saveScroll scrollTop: @refs.scrollable.scrollTop

    getStateFromStores: ->
        {accountID, mailboxID} = @props

        unless mailboxID
            return {messages: Immutable.Map()}

        account   = AccountStore.getByID accountID
        selection = SelectionGetters.getProps @props.messages
        nextstate = _.extend selection,
            login           : account?.get 'login'
            accountLabel    : account?.get 'label'
            selectedID      : RouterGetter.getCurrentMessageID()
            isLoading       : RouterGetter.isLoading()
            messagesLength  : @props.messages?.size
        return nextstate

    getEmptyListMessage: ->
        # FIXME : vérifier la valeur des filtres
        # poiur pouvoir faire ce test
        console.log 'getEmptyListMessage', @props.filter.type, MessageFilter.ALL
        # switch @props.filter.field
        #     when MessageFilter.FLAGGED
        #         t 'no flagged message'
        #     when MessageFilter.UNSEEN
        #         t 'no unseen message'
        #     when MessageFilter.ALL
        #         t 'list empty'
        #     else
        #         t 'no filter message'

    render: ->
        section
            key:               "messages-list-#{@props.mailboxID}"
            ref:               'list'
            'data-mailbox-id': @props.mailboxID
            className:         'messages-list panel'

            # Toolbar
            ToolbarMessagesList
                settings: SettingsStore.get()
                accountID: @props.accountID
                mailboxID: @props.mailboxID
                messages: @props.messages
                selection: @state.selection
                isAllSelected: @state.isAllSelected
                queryParams: @props.queryParams
                filter: @props.filter

            # Message List
            if @state.isLoading
                p className: 'listFetching list-loading', t 'list fetching'
            else
                unless @props.messages.size
                    p
                        className: 'list-empty'
                        ref: 'listEmpty'
                        @getEmptyListMessage()
                else
                    div
                        className: 'main-content'
                        ref: 'scrollable',
                        MessageListBody
                            messages: @props.messages
                            accountID: @props.accountID
                            mailboxID: @props.mailboxID
                            accountLabel: @state.accountLabel
                            login: @state.login
                            selection: @state.selection
                            ref: 'listBody'

                        if @props.hasNextPage
                            a
                                className: 'more-messages'
                                onClick: @loadMoreMessage,
                                ref: 'nextPage',
                                t 'list next page'
                        else
                            p ref: 'listEnd', t 'list end'

    loadMoreMessage: ->
        RouterActionCreator.saveScroll scrollTop: @refs.scrollable.scrollTop
        RouterActionCreator.getNextPage()

    _loadNext: ->
        # load next message if last one is displayed (useful when navigating
        # with keyboard)
        lastMessage = ReactDOM.findDOMNode(@refs.listBody)?.lastElementChild
        if lastMessage? and DomUtils.isVisible(lastMessage)
            @loadMoreMessage()

    _initScroll: ->
        if (value = @props.scrollValue?.scrollTop)?
            @refs.scrollable?.scrollTop = value

        @refs.scrollable?.addEventListener 'scroll', @_loadNext


    _resetScroll: ->
        @refs.scrollable?.removeEventListener 'scroll', @_loadNext
