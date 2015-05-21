# React components
{div, section, main, p, span, a, i, strong, form, input, button} = React.DOM
AccountConfig = require './account_config'
Alert         = require './alert'
Topbar        = require './topbar'
ToastContainer = require './toast_container'
Compose       = require './compose'
Conversation  = require './conversation'
Menu          = require './menu'
MessageList   = require './message-list'
Settings      = require './settings'
SearchForm    = require './search-form'
Tooltips      = require './tooltips-manager'

# React addons
ReactCSSTransitionGroup = React.addons.CSSTransitionGroup
classer = React.addons.classSet

# React Mixins
RouterMixin = require '../mixins/router_mixin'
StoreWatchMixin = require '../mixins/store_watch_mixin'
TooltipRefesherMixin = require '../mixins/tooltip_refresher_mixin'

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
        TooltipRefesherMixin
    ]

    render: ->
        # Shortcut
        # TODO: Improve the way we display a loader when app isn't ready
        layout = @props.router.current
        return div null, t "app loading" unless layout?

        disposition = LayoutStore.getDisposition()
        fullscreen  = LayoutStore.isPreviewFullscreen()

        alert = @state.alertMessage

        # Store current message ID if selected
        if layout.secondPanel? and layout.secondPanel.parameters.messageID?
            MessageStore.setCurrentID layout.secondPanel.parameters.messageID
        else
            MessageStore.setCurrentID null

        # F*** useless wrapper, just because of React limitations (╯°□°）╯︵ ┻━┻
        # @see https://facebook.github.io/react/tips/maximum-number-of-jsx-root-nodes.html
        # So, use it for layout classes, at least…
        layoutClasses = ['layout'
            "layout-#{LayoutStore.getDisposition()}"
            if fullscreen then "layout-preview-fullscreen"
            "layout-preview-#{LayoutStore.getPreviewSize()}"].join(' ')

        div className: layoutClasses,
            # Actual layout
            div className: 'app',
                # Menu is self-managed because this part of the layout
                # is always the same.
                Menu
                    ref:                   'menu'
                    accounts:              @state.accounts
                    refreshes:             @state.refreshes
                    selectedAccount:       @state.selectedAccount
                    selectedMailboxID:     @state.selectedMailboxID
                    isResponsiveMenuShown: @state.isResponsiveMenuShown
                    layout:                @props.router.current
                    mailboxes:             @state.mailboxesSorted
                    favorites:             @state.favoriteSorted
                    disposition:           disposition

                main
                    className: if layout.secondPanel? then null else 'full',
                    @getPanelComponent layout.firstPanel
                    if layout.secondPanel?
                        @getPanelComponent layout.secondPanel
                    else
                        section
                            key:             'placeholder'
                            'aria-expanded': false

            # Display feedback
            Alert { alert }
            ToastContainer()

            # Tooltips' content is declared once at the application level.
            # It's hidden so it doesn't break the layout. Other components
            # can then reference the tooltips by their ID to trigger them.
            Tooltips()

    # Factory of React components for panels
    getPanelComponent: (panelInfo) ->
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
            # direction = if layout is 'first' then 'secondPanel' \
            #     else 'firstPanel'

            fetching = MessageStore.isFetching()
            if @state.settings.get 'displayConversation'
                # select first conversation to allow navigation to start
                conversationID = MessageStore.getCurrentConversationID()
                if not conversationID? and messages.length > 0
                    conversationID = messages.first().get 'conversationID'
                conversationLengths = MessageStore.getConversationsLength()

            query = _.clone(MessageStore.getParams())
            query.accountID = accountID
            query.mailboxID = mailboxID

            # don't display conversations in Trash and Draft folders
            isDraft = @state.selectedAccount?.get('draftMailbox') is mailboxID
            isTrash = @state.selectedAccount?.get('trashMailbox') is mailboxID
            if isDraft or isTrash
                displayConversations = false
            else
                displayConversations = @state.settings.get 'displayConversation'

            return MessageList
                messages:             messages
                messagesCount:        messagesCount
                accountID:            accountID
                mailboxID:            mailboxID
                messageID:            messageID
                conversationID:       conversationID
                login:                AccountStore.getByID(accountID).get 'login'
                mailboxes:            @state.mailboxesFlat
                settings:             @state.settings
                fetching:             fetching
                refreshes:            @state.refreshes
                query:                query
                isTrash:              isTrash
                conversationLengths:  conversationLengths
                emptyListMessage:     emptyListMessage
                counterMessage:       counterMessage
                ref:                  'messageList'
                displayConversations: displayConversations

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

            # don't display conversations in Trash and Draft folders
            isDraft = @state.selectedAccount?.get('draftMailbox') is mailboxID
            isTrash = @state.selectedAccount?.get('trashMailbox') is mailboxID
            if isDraft or isTrash
                displayConversations = false
            else
                displayConversations = @state.settings.get 'displayConversation'

            prevMessage = MessageStore.getPreviousMessage()
            nextMessage = MessageStore.getNextMessage()

            return Conversation
                key: 'conversation-' + conversationID
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
                displayConversations : displayConversations
                useIntents           : LayoutStore.intentAvailable()

        # -- Generates the new message composition form
        else if panelInfo.action is 'compose'

            return Compose
                layout               : 'full'
                action               : null
                inReplyTo            : null
                settings             : @state.settings
                accounts             : @state.accountsFlat
                selectedAccountID    : @state.selectedAccount.get 'id'
                selectedAccountLogin : @state.selectedAccount.get 'login'
                message              : null
                useIntents           : LayoutStore.intentAvailable()
                ref                  : 'compose'

        # -- Generates the edit draft composition form
        else if panelInfo.action is 'edit'
            messageID = panelInfo.parameters.messageID
            message = MessageStore.getByID messageID

            return Compose
                layout               : 'full'
                action               : null
                inReplyTo            : null
                settings             : @state.settings
                accounts             : @state.accountsFlat
                selectedAccountID    : @state.selectedAccount.get 'id'
                selectedAccountLogin : @state.selectedAccount.get 'login'
                selectedMailboxID    : @state.selectedMailboxID
                message              : message
                useIntents           : LayoutStore.intentAvailable()
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
                trashMailbox: account.get 'trashMailbox'
                signature: account.get 'signature'
        .toJS()

        mailboxesFlat = {}
        mailboxes.map (mailbox) ->
            id = mailbox.get 'id'
            mailboxesFlat[id] = {}
            ['id', 'label', 'depth'].map (prop) ->
                mailboxesFlat[id][prop] = mailbox.get prop
        .toJS()

        # Test if the message view is currently displayed in large mode or not
        disposition = LayoutStore.getDisposition()

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
                    errorMsg = t 'account no special mailboxes'
                    LayoutActionCreator.alertError errorMsg


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
