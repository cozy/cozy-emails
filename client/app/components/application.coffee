# React components
{div, section, main, p, span, a, i, strong, form, input, button} = React.DOM
Alert          = require './alert'
Menu           = require './menu'
Modal          = require './modal'
Panel          = require './panel'
ToastContainer = require './toast_container'
Tooltips       = require './tooltips-manager'

# React Mixins
RouterMixin          = require '../mixins/router_mixin'
StoreWatchMixin      = require '../mixins/store_watch_mixin'
TooltipRefesherMixin = require '../mixins/tooltip_refresher_mixin'

# Flux stores
AccountStore  = require '../stores/account_store'
MessageStore  = require '../stores/message_store'
LayoutStore   = require '../stores/layout_store'
Stores        = [AccountStore, MessageStore, LayoutStore]

# Flux actions
LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

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
        previewSize = LayoutStore.getPreviewSize()

        modal = @state.modal

        layoutClasses = ['layout'
            "layout-#{disposition}"
            if fullscreen then "layout-preview-fullscreen"
            "layout-preview-#{previewSize}"].join(' ')

        div className: layoutClasses,
            # Actual layout
            div className: 'app',
                # Menu is self-managed because this part of the layout
                # is always the same.
                Menu
                    ref:                   'menu'
                    selectedAccount:       @state.selectedAccount
                    selectedMailboxID:     @state.selectedMailboxID
                    layout:                @props.router.current
                    disposition:           disposition

                main
                    className: if layout.secondPanel? then null else 'full',
                    @getPanel layout.firstPanel, 'firstPanel'
                    if layout.secondPanel?
                        @getPanel layout.secondPanel, 'secondPanel'
                    else
                        section
                            key:             'placeholder'
                            'aria-expanded': false

            # Display feedback
            if modal?
                Modal modal
            ToastContainer()

            # Tooltips' content is declared once at the application level.
            # It's hidden so it doesn't break the layout. Other components
            # can then reference the tooltips by their ID to trigger them.
            Tooltips()


    getPanel: (panel, ref) ->
        Panel
            ref               : ref
            action            : panel.action
            accountID         : panel.parameters.accountID
            mailboxID         : panel.parameters.mailboxID
            messageID         : panel.parameters.messageID
            tab               : panel.parameters.tab
            useIntents        : @state.useIntents
            selectedMailboxID : @state.selectedMailboxID


    getStateFromStores: ->

        selectedAccount = AccountStore.getSelected()
        # When selecting compose in Menu, we may not have a selected account
        if not selectedAccount?
            selectedAccount = AccountStore.getDefault()
        selectedAccountID = selectedAccount?.get('id') or null

        firstPanelInfo = @props.router.current?.firstPanel
        if firstPanelInfo?.action is 'account.mailbox.messages' or
           firstPanelInfo?.action is 'account.mailbox.messages.filter' or
           firstPanelInfo?.action is 'account.mailbox.messages.date'
            selectedMailboxID = firstPanelInfo.parameters.mailboxID
        else
            selectedMailboxID = null


        return {
            selectedAccount       : selectedAccount
            modal                 : LayoutStore.getModal()
            useIntents            : LayoutStore.intentAvailable()
            selectedMailboxID     : selectedMailboxID
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

            # Store current message ID if selected
            if secondPanel? and secondPanel.parameters.messageID?
                isConv = secondPanel.parameters.conversationID?
                messageID = secondPanel.parameters.messageID
                MessageActionCreator.setCurrent messageID, isConv
            else
                if firstPanel isnt 'compose'
                    MessageActionCreator.setCurrent null

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
                   action is 'account.mailbox.messages.filter' or
                   action is 'account.mailbox.messages.date' or
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

