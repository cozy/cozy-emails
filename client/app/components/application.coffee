# React components
{body, div, p, form, i, input, span, a, button, strong} = React.DOM
AccountConfig = require './account-config'
Alert         = require './alert'
Topbar        = require './topbar'
ToastContainer = require('./toast').Container
Compose       = require './compose'
Conversation  = require './conversation'
MailboxList   = require './mailbox-list'
Menu          = require './menu'
MessageList   = require './message-list'
Settings      = require './settings'
SearchForm = require './search-form'

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
TasksStore    = require '../stores/tasks_store'

# Flux actions
LayoutActionCreator = require '../actions/layout_action_creator'

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
        StoreWatchMixin [AccountStore, ContactStore, MessageStore, LayoutStore,
        SettingsStore, SearchStore]
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

        # css classes are a bit long so we use a subfunction to get them
        panelClasses = @getPanelClasses isFullWidth

        # classes for page-content
        responsiveClasses = classer
            'col-xs-12 col-md-11': true
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
        # Actual layout
        div className: 'container-fluid',
            div className: 'row',

                # Menu is self-managed because this part of the layout
                # is always the same.
                Menu
                    accounts: @state.accounts
                    selectedAccount: @state.selectedAccount
                    selectedMailboxID: @state.selectedMailboxID
                    isResponsiveMenuShown: @state.isResponsiveMenuShown
                    layout: @props.router.current
                    favoriteMailboxes: @state.favoriteMailboxes
                    unreadCounts: @state.unreadCounts

                div id: 'page-content', className: responsiveClasses,

                    # Display feedback
                    Alert { alert }
                    ToastContainer()

                    # The quick actions bar
                    Topbar
                        layout: @props.router.current
                        mailboxes: @state.mailboxes
                        selectedAccount: @state.selectedAccount
                        selectedMailboxID: @state.selectedMailboxID
                        searchQuery: @state.searchQuery
                        isResponsiveMenuShown: @state.isResponsiveMenuShown

                    # Two layout modes: one full-width panel or two panels
                    div id: 'panels', className: 'row',
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
            classes = firstPanel: 'panel col-xs-12 col-md-12'

            # custom case for mailbox.config action (top right cog button)
            if previous? and first.action is 'account.config'
                classes.firstPanel += ' moveFromTopRightCorner'

            # (default) when full-width panel is shown after
            # a two-panels structure
            else if previous? and previous.secondPanel

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
            classes =
                firstPanel: 'panel col-xs-12 col-md-6 hidden-xs hidden-sm'
                secondPanel: 'panel col-xs-12 col-md-6'

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
                emptyListMessage = t 'list search empty', query: @state.searchQuery
                counterMessage   = t 'list search count', messagesCount
            else
                accountID = panelInfo.parameters.accountID
                mailboxID = panelInfo.parameters.mailboxID
                messages  = MessageStore.getMessagesByMailbox mailboxID
                messagesCount = MessageStore.getMessagesCounts().get mailboxID
                emptyListMessage = t 'list empty'
                counterMessage   = t 'list count', messagesCount

            # gets the selected message if any
            messageID = MessageStore.getCurrentID()
            direction = if layout is 'first' then 'secondPanel' \
                else 'firstPanel'

            query = MessageStore.getParams()
            query.accountID = accountID
            query.mailboxID = mailboxID
            #paginationUrl = @buildUrl
            #    direction: 'first'
            #    action: 'account.mailbox.messages.full'
            #    parameters: query
            return MessageList
                messages:      messages
                messagesCount: messagesCount
                accountID:     accountID
                mailboxID:     mailboxID
                messageID:     messageID
                settings:      @state.settings
                query:         query
                emptyListMessage: emptyListMessage
                counterMessage:   counterMessage
                #paginationUrl: paginationUrl

        # -- Generates a configuration window for a given account
        else if panelInfo.action is 'account.config' or
                panelInfo.action is 'account.new'
            # don't use @state.selectedAccount
            selectedAccount   = AccountStore.getSelected()
            error             = AccountStore.getError()
            isWaiting         = AccountStore.isWaiting()
            mailboxes         = AccountStore.getSelectedMailboxes true
            favoriteMailboxes = @state.favoriteMailboxes
            if selectedAccount and not error and mailboxes.length is 0
                error =
                    name: 'AccountConfigError'
                    field: 'nomailboxes'

            return AccountConfig {error, isWaiting, selectedAccount,
                mailboxes, favoriteMailboxes}

        # -- Generates a configuration window to create a new account
        #else if panelInfo.action is 'account.new'
        #    error = AccountStore.getError()
        #    isWaiting = AccountStore.isWaiting()
        #    return AccountConfig {layout, error, isWaiting}

        # -- Generates a conversation
        else if panelInfo.action is 'message' or
                panelInfo.action is 'conversation'

            messageID      = panelInfo.parameters.messageID
            message        = MessageStore.getByID messageID
            if message?
                conversationID = message.get 'conversationID'
                conversation   = MessageStore.getConversation conversationID
                MessageStore.setCurrentID message.get('id')

            return Conversation
                layout            : layout
                settings          : @state.settings
                accounts          : @state.accounts
                mailboxes         : @state.mailboxes
                selectedAccount   : @state.selectedAccount
                selectedMailboxID : @state.selectedMailboxID
                message           : message
                conversation      : conversation
                prevID            : MessageStore.getPreviousMessage()
                nextID            : MessageStore.getNextMessage()

        # -- Generates the new message composition form
        else if panelInfo.action is 'compose'

            return Compose
                layout          : layout
                action          : null
                inReplyTo       : null
                settings        : @state.settings
                accounts        : @state.accounts
                selectedAccount : @state.selectedAccount
                message         : null

        # -- Generates the edit draft composition form
        else if panelInfo.action is 'edit'

            messageID = panelInfo.parameters.messageID
            message = MessageStore.getByID messageID

            return Compose
                layout          : layout
                action          : null
                inReplyTo       : null
                settings        : @state.settings
                accounts        : @state.accounts
                selectedAccount : @state.selectedAccount
                message         : message

        # -- Display the settings form
        else if panelInfo.action is 'settings'
            settings = @state.settings
            return Settings {settings}

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

        return {
            accounts: AccountStore.getAll()
            selectedAccount: selectedAccount
            isResponsiveMenuShown: LayoutStore.isMenuShown()
            alertMessage: LayoutStore.getAlert()
            mailboxes: AccountStore.getSelectedMailboxes true
            selectedMailboxID: selectedMailboxID
            selectedMailbox: AccountStore.getSelectedMailbox selectedMailboxID
            favoriteMailboxes: AccountStore.getSelectedFavorites()
            unreadCounts: MessageStore.getUnreadMessagesCounts()
            searchQuery: SearchStore.getQuery()
            settings: SettingsStore.get()
            plugins: window.plugins
        }


    # Listens to router changes. Renders the component on changes.
    componentWillMount: ->
        # Uses `forceUpdate` with the proper scope because React doesn't allow
        # to rebind its scope on the fly
        @onRoute = (params) =>
            {firstPanelInfo, secondPanelInfo} = params
            @forceUpdate()

        @props.router.on 'fluxRoute', @onRoute


    # Stops listening to router changes
    componentWillUnmount: ->
        @props.router.off 'fluxRoute', @onRoute

