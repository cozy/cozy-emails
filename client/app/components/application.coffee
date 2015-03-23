# React components
{body, div, p, form, i, input, span, a, button, strong} = React.DOM
AccountConfig = require './account-config'
Alert         = require './alert'
Topbar        = require './topbar'
ToastContainer = require('./toast').Container
Compose       = require './compose'
Conversation  = require './conversation'
Menu          = require './menu'
MessageList   = require './message-list'
Settings      = require './settings'
SearchForm    = require './search-form'

# React addons
ReactCSSTransitionGroup = React.addons.CSSTransitionGroup
classer = React.addons.classSet

# React Mixins
RouterMixin = require '../mixins/router_mixin'
StoreWatchMixin = require '../mixins/store_watch_mixin'

# Flux stores
AccountStore  = require '../stores/account_store'
ContactStore  = require '../stores/contact_store'
MessageStore  = require '../stores/message_store'
LayoutStore   = require '../stores/layout_store'
SettingsStore = require '../stores/settings_store'
SearchStore   = require '../stores/search_store'
RefreshesStore = require '../stores/refreshes_store'
Stores = [AccountStore, ContactStore, MessageStore, LayoutStore,
        SettingsStore, SearchStore, RefreshesStore]

# Flux actions
LayoutActionCreator = require '../actions/layout_action_creator'

{MessageFilter, Dispositions} = require '../constants/app_constants'

###
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly

    About routing: it uses Backbone.Router as a source of truth for the layout.
    (based on:
        https://medium.com/react-tutorials/react-backbone-router-c00be0cf1592)
###
module.exports = Application = React.createClass
    displayName: 'Application'

    mixins: [
        StoreWatchMixin Stores
        RouterMixin
    ]

    render: ->
        # Shortcut
        layout = @props.router.current
        if not layout?
            return div null, t "app loading"

        # is the layout a full-width panel or two panels sharing the width
        isFullWidth = not layout.secondPanel?

        firstPanelLayoutMode = if isFullWidth then 'full' else 'first'
        disposition = LayoutStore.getDisposition()

        panelsClasses = classer
            row: true
            horizontal: disposition.type is Dispositions.HORIZONTAL
            three: disposition.type is Dispositions.THREE
            vertical: disposition.type is Dispositions.VERTICAL
            full: isFullWidth
        # css classes are a bit long so we use a subfunction to get them
        panelClasses = @getPanelClasses isFullWidth

        # classes for page-content
        responsiveClasses = classer
            'col-xs-12': true
            'col-md-9':  disposition.type is Dispositions.THREE
            'col-md-11': disposition.type isnt Dispositions.THREE
            'pushed': @state.isResponsiveMenuShown

        alert = @state.alertMessage

        getUrl = (mailbox) =>
            @buildUrl
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: [
                    @state.selectedAccount?.get('id'),
                    mailbox.get('id')
                ]

        keyFirst = 'left-panel-' + layout.firstPanel.action.split('.')[0]
        if layout.secondPanel?
            keySecond = 'right-panel-' + layout.secondPanel.action.split('.')[0]
            # update current message id
            # this need to be done here, so MessageList get the good message ID
            if layout.secondPanel.parameters.messageID?
                MessageStore.setCurrentID layout.secondPanel.parameters.messageID

        # Actual layout
        div className: 'container-fluid',
            div className: 'row',

                # Menu is self-managed because this part of the layout
                # is always the same.
                Menu
                    ref: 'menu'
                    accounts: @state.accounts
                    refreshes: @state.refreshes
                    selectedAccount: @state.selectedAccount
                    selectedMailboxID: @state.selectedMailboxID
                    isResponsiveMenuShown: @state.isResponsiveMenuShown
                    layout: @props.router.current
                    mailboxes: @state.mailboxesSorted
                    favorites: @state.favoriteSorted
                    disposition: disposition
                    toggleMenu: @toggleMenu

                div id: 'page-content', className: responsiveClasses,

                    # Display feedback
                    Alert { alert }
                    ToastContainer()

                    #a onClick: @toggleMenu,
                    #    className: 'responsive-handler hidden-md hidden-lg',
                            #i className: 'fa fa-bars pull-left'
                            #t "app menu"
                    # The quick actions bar
                    #Topbar
                    #    ref: 'topbar'
                    #    layout: @props.router.current
                    #    mailboxes: @state.mailboxes
                    #    selectedAccount: @state.selectedAccount
                    #    selectedMailboxID: @state.selectedMailboxID
                    #    searchQuery: @state.searchQuery
                    #    isResponsiveMenuShown: @state.isResponsiveMenuShown

                    # Two layout modes: one full-width panel or two panels
                    div id: 'panels', className: panelsClasses,
                        div
                            className: panelClasses.firstPanel,
                            key: keyFirst,
                                @getPanelComponent layout.firstPanel,
                                    firstPanelLayoutMode
                        if not isFullWidth and layout.secondPanel?
                            div
                                className: panelClasses.secondPanel,
                                key: keySecond,
                                    @getPanelComponent layout.secondPanel,
                                        'second'


    # Panels CSS classes are a bit long so we get them from a this subfunction
    # Also, it manages transitions between screens by adding relevant classes
    getPanelClasses: (isFullWidth) ->
        previous = @props.router.previous
        layout   = @props.router.current
        first    = layout.firstPanel
        second   = layout.secondPanel

        # Two cases: the layout has a full-width panel...
        if isFullWidth
            classes = firstPanel: 'panel col-xs-12 col-md-12 row-10'

            # (default) when full-width panel is shown after
            # a two-panels structure
            if previous? and previous.secondPanel

                # if the full-width panel was on right right before, it expands
                if previous.secondPanel.action is layout.firstPanel.action and
                   _.difference(previous.secondPanel.parameters,
                        layout.firstPanel.parameters).length is 0
                    classes.firstPanel += ' expandFromRight'

            # (default) when full-width panel is shown after a full-width panel
            else if previous?
                classes.firstPanel += ' moveFromLeft'


        # ... or a two panels layout.
        else
            disposition = LayoutStore.getDisposition()
            if disposition.type is Dispositions.HORIZONTAL
                classes =
                    firstPanel: "panel col-xs-12 col-md-12 hidden-xs hidden-sm row-#{disposition.height}"
                    secondPanel: "panel col-xs-12 col-md-12 row-#{10 - disposition.height} row-offset-#{disposition.height}"
            else
                classes =
                    firstPanel: "panel col-xs-12 col-md-#{disposition.width} hidden-xs hidden-sm row-10"
                    secondPanel: "panel col-xs-12 col-md-#{12 - disposition.width} col-offset-#{disposition.width} row-10"

            # we don't animate in the first render
            if previous?
                wasFullWidth = not previous.secondPanel?

                # transition from full-width to two-panels layout
                if wasFullWidth and not isFullWidth

                    # expanded second panel collapses
                    if previous.firstPanel.action is second.action and
                       _.difference(previous.firstPanel.parameters,
                            second.parameters).length is 0
                        classes.firstPanel += ' moveFromLeft'
                        classes.secondPanel += ' slide-in-from-left'

                    # (default) opens second panel sliding from the right
                    else
                        classes.secondPanel += ' slide-in-from-right'

                # (default) opens second panel sliding from the left
                else if not isFullWidth
                    classes.secondPanel += ' slide-in-from-left'

        return classes


    # Factory of React components for panels
    getPanelComponent: (panelInfo, layout) ->

        # -- Generates a list of messages for a given account and mailbox
        if panelInfo.action is 'account.mailbox.messages' or
           panelInfo.action is 'account.mailbox.messages.full' or
           panelInfo.action is 'search'

            if panelInfo.action is 'search'
                accountID = null
                mailboxID = null
                messages  = SearchStore.getResults()
                messagesCount    = messages.count()
                emptyListMessage = t 'list search empty',
                    query: @state.searchQuery
                counterMessage   = t 'list search count', messagesCount
            else
                accountID = panelInfo.parameters.accountID
                mailboxID = panelInfo.parameters.mailboxID
                account   = AccountStore.getByID accountID
                if account?
                    mailbox   = account.get('mailboxes').get mailboxID
                    messages  = MessageStore.getMessagesByMailbox mailboxID,
                        @state.settings.get('displayConversation')
                    messagesCount = mailbox?.get('nbTotal') or 0
                    emptyListMessage = switch MessageStore.getCurrentFilter()
                        when MessageFilter.FLAGGED
                            t 'no flagged message'
                        when MessageFilter.UNSEEN
                            t 'no unseen message'
                        when MessageFilter.ALL
                            t 'list empty'
                        else
                            t 'no filter message'
                    counterMessage   = t 'list count', messagesCount
                else
                    @redirect
                        direction: "first"
                        action: "default"
                    return

            # gets the selected message if any
            messageID = MessageStore.getCurrentID()
            direction = if layout is 'first' then 'secondPanel' \
                else 'firstPanel'

            fetching = MessageStore.isFetching()
            if @state.settings.get 'displayConversation'
                # select first conversation to allow navigation to start
                conversationID = MessageStore.getCurrentConversationID()
                if not conversationID? and messages.length > 0
                    conversationID = messages.first().get 'conversationID'
                    conversation = MessageStore.getConversation conversationID
                conversationLengths = MessageStore.getConversationsLength()

            query = _.clone(MessageStore.getParams())
            query.accountID = accountID
            query.mailboxID = mailboxID

            isTrash = @state.selectedAccount?.get('trashMailbox') is mailboxID

            return MessageList
                messages:      messages
                messagesCount: messagesCount
                accountID:     accountID
                mailboxID:     mailboxID
                messageID:     messageID
                conversationID: conversationID
                login:         AccountStore.getByID(accountID).get 'login'
                mailboxes:     @state.mailboxesFlat
                settings:      @state.settings
                fetching:      fetching
                refreshes:     @state.refreshes
                query:         query
                isTrash:       isTrash
                conversationLengths: conversationLengths
                emptyListMessage: emptyListMessage
                counterMessage:   counterMessage
                ref:           'messageList'
                toggleMenu: @toggleMenu

        # -- Generates a configuration window for a given account
        else if panelInfo.action is 'account.config'
            # don't use @state.selectedAccount
            ref               = "accountConfig"
            selectedAccount   = AccountStore.getSelected()
            error             = AccountStore.getError()
            isWaiting         = AccountStore.isWaiting()
            mailboxes         = AccountStore.getSelectedMailboxes()
            favoriteMailboxes = @state.favoriteMailboxes
            tab = panelInfo.parameters.tab
            if selectedAccount and not error and mailboxes.length is 0
                error =
                    name: 'AccountConfigError'
                    field: 'nomailboxes'

            return AccountConfig {error, isWaiting, selectedAccount,
                mailboxes, favoriteMailboxes, tab, ref}

        else if panelInfo.action is 'account.new'
            return AccountConfig
                ref: "accountConfig"
                error: AccountStore.getError()
                isWaiting: AccountStore.isWaiting()

        # -- Generates a conversation
        else if panelInfo.action is 'message' or
                panelInfo.action is 'conversation'

            messageID      = panelInfo.parameters.messageID
            message        = MessageStore.getByID messageID
            selectedMailboxID = @state.selectedMailboxID
            if message?
                conversationID = message.get 'conversationID'
                lengths = MessageStore.getConversationsLength()
                conversationLength = lengths.get conversationID
                conversation = MessageStore.getConversation conversationID
                selectedMailboxID ?= Object.keys(message.get('mailboxIDs'))[0]

            prevMessage = MessageStore.getPreviousMessage()
            nextMessage = MessageStore.getNextMessage()

            return Conversation
                key: 'conversation-' + conversationID
                layout               : layout
                settings             : @state.settings
                accounts             : @state.accountsFlat
                mailboxes            : @state.mailboxesFlat
                selectedAccountID    : @state.selectedAccount.get 'id'
                selectedAccountLogin : @state.selectedAccount.get 'login'
                selectedMailboxID    : selectedMailboxID
                message              : message
                conversation         : conversation
                conversationLength   : conversationLength
                prevMessageID        : prevMessage?.get 'id'
                prevConversationID   : prevMessage?.get 'conversationID'
                nextMessageID        : nextMessage?.get 'id'
                nextConversationID   : nextMessage?.get 'conversationID'
                ref                  : 'conversation'

        # -- Generates the new message composition form
        else if panelInfo.action is 'compose'

            return Compose
                layout               : layout
                action               : null
                inReplyTo            : null
                settings             : @state.settings
                accounts             : @state.accountsFlat
                selectedAccountID    : @state.selectedAccount.get 'id'
                selectedAccountLogin : @state.selectedAccount.get 'login'
                message              : null
                ref                  : 'compose'

        # -- Generates the edit draft composition form
        else if panelInfo.action is 'edit'

            messageID = panelInfo.parameters.messageID
            message = MessageStore.getByID messageID

            return Compose
                layout               : layout
                action               : null
                inReplyTo            : null
                settings             : @state.settings
                accounts             : @state.accountsFlat
                selectedAccountID    : @state.selectedAccount.get 'id'
                selectedAccountLogin : @state.selectedAccount.get 'login'
                selectedMailboxID    : @state.selectedMailboxID
                message              : message
                ref                  : 'compose'

        # -- Display the settings form
        else if panelInfo.action is 'settings'
            settings = @state.settings
            return Settings
                ref     : 'settings'
                settings: @state.settings

        # -- Error case, shouldn't happen. Might be worth to make it pretty.
        else return div null, 'Unknown component'

    getStateFromStores: ->

        selectedAccount = AccountStore.getSelected()
        # When selecting compose in Menu, we may not have a selected account
        if not selectedAccount?
            selectedAccount = AccountStore.getDefault()
        selectedAccountID = selectedAccount?.get('id') or null

        firstPanelInfo = @props.router.current?.firstPanel
        if firstPanelInfo?.action is 'account.mailbox.messages' or
           firstPanelInfo?.action is 'account.mailbox.messages.full'
            selectedMailboxID = firstPanelInfo.parameters.mailboxID
        else
            selectedMailboxID = null

        accounts  = AccountStore.getAll()
        mailboxes = AccountStore.getSelectedMailboxes()

        # Flat copies of accounts and mailboxes
        # This prevents components to refresh when properties they don't use are
        # updated (unread counts, timestamp of last refresh…)
        accountsFlat = {}
        accounts.map (account) ->
            accountsFlat[account.get 'id'] =
                name:  account.get 'name'
                label: account.get 'label'
                login: account.get 'login'
        .toJS()

        mailboxesFlat = {}
        mailboxes.map (mailbox) ->
            id = mailbox.get 'id'
            mailboxesFlat[id] = {}
            ['id', 'label', 'depth'].map (prop) ->
                mailboxesFlat[id][prop] = mailbox.get prop
        .toJS()

        return {
            accounts: accounts
            accountsFlat: accountsFlat
            selectedAccount: selectedAccount
            isResponsiveMenuShown: false
            alertMessage: LayoutStore.getAlert()
            mailboxes: mailboxes
            mailboxesSorted: AccountStore.getSelectedMailboxes true
            mailboxesFlat: mailboxesFlat
            selectedMailboxID: selectedMailboxID
            selectedMailbox: AccountStore.getSelectedMailbox selectedMailboxID
            favoriteMailboxes: AccountStore.getSelectedFavorites()
            favoriteSorted: AccountStore.getSelectedFavorites true
            searchQuery: SearchStore.getQuery()
            refreshes: RefreshesStore.getRefreshing()
            settings: SettingsStore.get()
            plugins: window.plugins
        }


    # Listens to router changes. Renders the component on changes.
    componentWillMount: ->
        # Uses `forceUpdate` with the proper scope because React doesn't allow
        # to rebind its scope on the fly
        @onRoute = (params) =>
            {firstPanel, secondPanel} = params
            if firstPanel?
                @checkAccount firstPanel.action
            if secondPanel?
                @checkAccount secondPanel.action
            @forceUpdate()

        @props.router.on 'fluxRoute', @onRoute

    checkAccount: (action) ->
        # "special" mailboxes must be set before accessing to the account
        # otherwise, redirect to account config
        account = @state.selectedAccount
        if (account?)
            if not account.get('draftMailbox')? or
               not account.get('sentMailbox')? or
               not account.get('trashMailbox')?

                if action is 'account.mailbox.messages' or
                   action is 'account.mailbox.messages.full' or
                   action is 'search' or
                   action is 'message' or
                   action is 'conversation' or
                   action is 'compose' or
                   action is 'edit'
                    @redirect
                        direction: 'first'
                        action: 'account.config'
                        parameters: [
                            account.get 'id'
                            'mailboxes'
                        ]
                        fullWidth: true
                    LayoutActionCreator.alertError t 'account no special mailboxes'

    _notify: (title, options) ->
        window.cozyMails.notify title, options

    componentDidMount: ->
        Stores.forEach (store) =>
            store.on 'notify', @_notify

    componentWillUnmount: ->
        Stores.forEach (store) =>
            store.removeListener 'notify', @notify
        # Stops listening to router changes
        @props.router.off 'fluxRoute', @onRoute

    # Toggle the menu in responsive mode
    toggleMenu: (event) ->
        @setState isResponsiveMenuShown: not @state.isResponsiveMenuShown

