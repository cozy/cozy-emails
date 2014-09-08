# React components
{body, div, p, form, i, input, span, a, button, strong} = React.DOM
AccountConfig = require './account-config'
Alert         = require './alert'
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
RouterMixin = require '../mixins/RouterMixin'
StoreWatchMixin = require '../mixins/StoreWatchMixin'

# Flux stores
AccountStore  = require '../stores/AccountStore'
MessageStore  = require '../stores/MessageStore'
LayoutStore   = require '../stores/LayoutStore'
SettingsStore = require '../stores/SettingsStore'
SearchStore   = require '../stores/SearchStore'

# Flux actions
LayoutActionCreator = require '../actions/LayoutActionCreator'

###
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly

    About routing: it uses Backbone.Router as a source of truth for the layout.
    (based on: https://medium.com/react-tutorials/react-backbone-router-c00be0cf1592)
###
module.exports = Application = React.createClass
    displayName: 'Application'

    mixins: [
        StoreWatchMixin [AccountStore, MessageStore, LayoutStore, SearchStore]
        RouterMixin
    ]

    render: ->
        # Shortcut
        layout = @props.router.current
        if not layout?
            return div null, t "app loading"

        # is the layout a full-width panel or two panels sharing the width
        isFullWidth = not layout.rightPanel?

        leftPanelLayoutMode = if isFullWidth then 'full' else 'left'

        # css classes are a bit long so we use a subfunction to get them
        panelClasses = @getPanelClasses isFullWidth

        showMailboxConfigButton = @state.selectedAccount? and
                                  layout.leftPanel.action isnt 'account.new'
        if showMailboxConfigButton
            # the button toggles the mailbox config
            if layout.leftPanel.action is 'account.config'
                configMailboxUrl = @buildUrl
                    direction: 'left'
                    action: 'account.mailbox.messages'
                    parameters: @state.selectedAccount.get 'id'
                    fullWidth: true
            else
                configMailboxUrl = @buildUrl
                    direction: 'left'
                    action: 'account.config'
                    parameters: @state.selectedAccount.get 'id'
                    fullWidth: true

        responsiveBackUrl = @buildUrl
            leftPanel: layout.leftPanel
            fullWidth: true

        # classes for page-content
        responsiveClasses = classer
            'col-xs-12 col-md-11': true
            'pushed': @state.isResponsiveMenuShown

        alert = @state.alertMessage

        # Actual layout
        div className: 'container-fluid',
            div className: 'row',

                # Menu is self-managed because this part of the layout
                # is always the same.
                Menu
                    accounts: @state.accounts
                    selectedAccount: @state.selectedAccount
                    isResponsiveMenuShown: @state.isResponsiveMenuShown
                    layout: @props.router.current
                    favoriteMailboxes: @state.favoriteMailboxes

                div id: 'page-content', className: responsiveClasses,

                    # Display feedback
                    Alert { alert }

                    # The quick actions bar shoud be moved in its own component
                    # when its feature is implemented.
                    div id: 'quick-actions', className: 'row',
                        # responsive menu icon
                        if layout.rightPanel
                            a href: responsiveBackUrl, className: 'responsive-handler hidden-md hidden-lg',
                                i className: 'fa fa-chevron-left hidden-md hidden-lg pull-left'
                                t "app back"
                        else
                            a onClick: @onResponsiveMenuClick, className: 'responsive-handler hidden-md hidden-lg',
                                i className: 'fa fa-bars pull-left'
                                t "app menu"


                        div className: 'col-md-6 hidden-xs hidden-sm pull-left',
                            form className: 'form-inline col-md-12',
                                MailboxList
                                    selectedAccount: @state.selectedAccount
                                    mailboxes: @state.mailboxes
                                    selectedMailbox: @state.selectedMailbox
                                SearchForm query: @state.searchQuery

                        div id: 'contextual-actions', className: 'col-md-6 hidden-xs hidden-sm pull-left text-right',
                            ReactCSSTransitionGroup transitionName: 'fade',
                                if showMailboxConfigButton
                                    a href: configMailboxUrl, className: 'btn btn-cozy mailbox-config',
                                        i className: 'fa fa-cog'

                    # Two layout modes: one full-width panel or two panels
                    div id: 'panels', className: 'row',
                        div className: panelClasses.leftPanel, key: 'left-panel-' + layout.leftPanel.action + '-' + layout.leftPanel.parameters.join('-'),
                            @getPanelComponent layout.leftPanel, leftPanelLayoutMode
                        if not isFullWidth and layout.rightPanel?
                            div className: panelClasses.rightPanel, key: 'right-panel-' + layout.rightPanel.action + '-' + layout.rightPanel.parameters.join('-'),
                                @getPanelComponent layout.rightPanel, 'right'


    # Panels CSS classes are a bit long so we get them from a this subfunction
    # Also, it manages transitions between screens by adding relevant classes
    getPanelClasses: (isFullWidth) ->
        previous = @props.router.previous
        layout = @props.router.current
        left = layout.leftPanel
        right = layout.rightPanel

        # Two cases: the layout has a full-width panel...
        if isFullWidth
            classes = leftPanel: 'panel col-xs-12 col-md-12'

            # custom case for mailbox.config action (top right cog button)
            if previous? and left.action is 'account.config'
                classes.leftPanel += ' moveFromTopRightCorner'

            # (default) when full-width panel is shown after a two-panels structure
            else if previous? and previous.rightPanel

                # if the full-width panel was on right right before, it expands
                if previous.rightPanel.action is layout.leftPanel.action and
                   _.difference(previous.rightPanel.parameters, layout.leftPanel.parameters).length is 0
                    classes.leftPanel += ' expandFromRight'

            # (default) when full-width panel is shown after a full-width panel
            else if previous?
                classes.leftPanel += ' moveFromLeft'


        # ... or a two panels layout.
        else
            classes =
                leftPanel: 'panel col-xs-12 col-md-6 hidden-xs hidden-sm'
                rightPanel: 'panel col-xs-12 col-md-6'

            # we don't animate in the first render
            if previous?
                wasFullWidth = not previous.rightPanel?

                # transition from full-width to two-panels layout
                if wasFullWidth and not isFullWidth

                    # expanded right panel collapses
                    if previous.leftPanel.action is right.action and
                       _.difference(previous.leftPanel.parameters, right.parameters).length is 0
                        classes.leftPanel += ' moveFromLeft'
                        classes.rightPanel += ' slide-in-from-left'

                    # (default) opens right panel sliding from the right
                    else
                        classes.rightPanel += ' slide-in-from-right'

                # (default) opens right panel sliding from the left
                else if not isFullWidth
                    classes.rightPanel += ' slide-in-from-left'

        return classes


    # Factory of React components for panels
    getPanelComponent: (panelInfo, layout) ->

        # -- Generates a list of messages for a given account and mailbox
        if panelInfo.action is 'account.mailbox.messages'
            accountID = panelInfo.parameters[0]
            mailboxID = panelInfo.parameters[1]
            pageNum   = panelInfo.parameters[2] ? 1
            numPerPage      = @state.settings.get 'messagesPerPage'
            firstOfPage     = ( pageNum - 1 ) * numPerPage
            lastOfPage      = ( pageNum * numPerPage )

            # gets the selected message if any
            openMessage = null
            direction = if layout is 'left' then 'rightPanel' else 'leftPanel'
            otherPanelInfo = @props.router.current[direction]
            if otherPanelInfo?.action is 'message'
                openMessage = MessageStore.getByID otherPanelInfo.parameters[0]

            messagesCount = MessageStore.getMessagesCountByMailbox mailboxID
            return MessageList
                messages: MessageStore.getMessagesByMailbox mailboxID, firstOfPage, lastOfPage
                messagesCount: messagesCount
                accountID: accountID
                mailboxID: mailboxID
                layout: layout
                openMessage: openMessage
                messagesPerPage: numPerPage
                pageNum: pageNum
                emptyListMessage: t 'list empty'
                counterMessage: t 'list count', messagesCount
                buildPaginationUrl: (numPage) =>
                    @buildUrl
                        direction: 'left'
                        action: 'account.mailbox.messages'
                        parameters: [accountID, mailboxID, numPage]

        # -- Generates a configuration window for a given account
        else if panelInfo.action is 'account.config'
            initialAccountConfig = @state.selectedAccount
            error = AccountStore.getError()
            isWaiting = AccountStore.isWaiting()
            return AccountConfig {layout, error, isWaiting, initialAccountConfig}

        # -- Generates a configuration window to create a new account
        else if panelInfo.action is 'account.new'
            error = AccountStore.getError()
            isWaiting = AccountStore.isWaiting()
            return AccountConfig {layout, error, isWaiting}

        # -- Generates a conversation
        else if panelInfo.action is 'message'
            message = MessageStore.getByID panelInfo.parameters[0]
            conversation = MessageStore.getMessagesByConversation panelInfo.parameters[0]
            selectedAccount = @state.selectedAccount
            return Conversation {message, conversation, selectedAccount, layout}

        # -- Generates the new message composition form
        else if panelInfo.action is 'compose'
            selectedAccount = @state.selectedAccount
            accounts = @state.accounts
            message  = null
            action   = null
            return Compose {selectedAccount, layout, accounts, message, action}

        # -- Display the settings form
        else if panelInfo.action is 'settings'
            settings = @state.settings
            return Settings {settings}

        # -- Generates a message list based on search result
        else if panelInfo.action is 'search'
            accountID = null
            mailboxID = null
            pageNum   = panelInfo.parameters[1]
            numPerPage      = @state.settings.get 'messagesPerPage'
            firstOfPage     = ( pageNum - 1 ) * numPerPage
            lastOfPage      = ( pageNum * numPerPage )

            # gets the selected message if any
            openMessage = null
            direction = if layout is 'left' then 'rightPanel' else 'leftPanel'
            otherPanelInfo = @props.router.current[direction]
            if otherPanelInfo?.action is 'message'
                openMessage = MessageStore.getByID otherPanelInfo.parameters[0]

            results = SearchStore.getResults()
            return MessageList
                messages: results
                messagesCount: results.count()
                accountID: accountID
                mailboxID: mailboxID
                layout: layout
                openMessage: openMessage
                messagesPerPage: numPerPage
                pageNum: pageNum
                emptyListMessage: t 'list search empty', query: @state.searchQuery
                counterMessage: t 'list search count', results.count()
                buildPaginationUrl: (numPage) =>
                    @buildUrl
                        direction: 'left'
                        action: 'search'
                        parameters: [@state.searchQuery, numPage]

        # -- Error case, shouldn't happen. Might be worth to make it pretty.
        else return div null, 'Unknown component'

    getStateFromStores: ->

        selectedAccount = AccountStore.getSelected()
        selectedAccountID = selectedAccount?.get('id') or null

        leftPanelInfo = @props.router.current?.leftPanel
        if leftPanelInfo?.action is 'account.mailbox.messages'
            selectedMailboxID = leftPanelInfo.parameters[1]
        else
            selectedMailboxID = null

        return {
            accounts: AccountStore.getAll()
            selectedAccount: selectedAccount
            isResponsiveMenuShown: LayoutStore.isMenuShown()
            alertMessage: LayoutStore.getAlert()
            mailboxes: AccountStore.getSelectedMailboxes true
            selectedMailbox: AccountStore.getSelectedMailbox selectedMailboxID
            favoriteMailboxes: AccountStore.getSelectedFavorites()
            searchQuery: SearchStore.getQuery()
            settings: SettingsStore.get()
        }


    # Listens to router changes. Renders the component on changes.
    componentWillMount: ->
        # Uses `forceUpdate` with the proper scope because React doesn't allow
        # to rebind its scope on the fly
        @onRoute = (params) =>
            {leftPanelInfo, rightPanelInfo} = params
            @forceUpdate()

        @props.router.on 'fluxRoute', @onRoute


    # Stops listening to router changes
    componentWillUnmount: ->
        @props.router.off 'fluxRoute', @onRoute

    # Toggle the menu in responsive mode
    onResponsiveMenuClick: (event) ->
        event.preventDefault()
        if @state.isResponsiveMenuShown
            LayoutActionCreator.hideReponsiveMenu()
        else
            LayoutActionCreator.showReponsiveMenu()
