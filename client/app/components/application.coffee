require '../styles/application.styl'

React = require 'react'

# React components
{div, section, main, p, span, a, i, strong, form, input, button} = React.DOM
Menu           = React.createFactory require './menu'
Modal          = React.createFactory require './modal'
Panel          = React.createFactory require './panel'
ToastContainer = React.createFactory require './toast_container'
Tooltips       = React.createFactory require './tooltips-manager'

# React Mixins
RouterMixin          = require '../mixins/router_mixin'
StoreWatchMixin      = require '../mixins/store_watch_mixin'
TooltipRefesherMixin = require '../mixins/tooltip_refresher_mixin'

# Flux stores
AccountStore  = require '../stores/account_store'
MessageStore  = require '../stores/message_store'
LayoutStore   = require '../stores/layout_store'
SearchStore   = require '../stores/search_store'
Stores        = [AccountStore, MessageStore, LayoutStore, SearchStore]

# Flux actions
LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

{MessageFilter} = require '../constants/app_constants'

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
        isCompact   = LayoutStore.getListModeCompact()
        fullscreen  = LayoutStore.isPreviewFullscreen()
        previewSize = LayoutStore.getPreviewSize()

        modal = @state.modal

        layoutClasses = ['layout'
            "layout-#{disposition}"
            if isCompact then "layout-compact"
            if fullscreen then "layout-preview-fullscreen"
            "layout-preview-#{previewSize}"].join(' ')

        div className: layoutClasses,
            # Actual layout
            div className: 'app',
                # Menu is self-managed because this part of the layout
                # is always the same.
                Menu ref: 'menu', layout: @props.router.current

                main
                    className: if layout.secondPanel? then null else 'full',

                    div
                        className: 'panels'

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
            Tooltips(key: "tooltips")


    getPanel: (panel, ref) ->
        params = panel.parameters
        prefix = ref + '-' + params.mailboxID
        Panel
            ref               : ref
            key               : MessageStore.getQueryKey prefix
            action            : panel.action
            accountID         : params.accountID
            mailboxID         : params.mailboxID
            messageID         : params.messageID
            tab               : params.tab
            useIntents        : @state.useIntents
            selectedMailboxID : @state.selectedMailboxID


    getStateFromStores: ->
        selectedAccount = AccountStore.getSelectedOrDefault()

        firstPanelInfo = @props.router.current?.firstPanel
        if firstPanelInfo?.action is 'account.mailbox.messages'
            selectedMailboxID = firstPanelInfo.parameters.mailboxID
        else
            selectedMailboxID = null


        return {
            selectedAccount       : selectedAccount
            currentSearch         : SearchStore.getCurrentSearch()
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
                # Remove Fullscreen
                LayoutActionCreator.toggleFullscreen false

                if firstPanel isnt 'compose'
                    MessageActionCreator.setCurrent null

            @forceUpdate()

        @props.router.on 'fluxRoute', @onRoute

    checkAccount: (action) ->
        # "special" mailboxes must be set before accessing to the account
        # otherwise, redirect to account config
        account = @state.selectedAccount

        noSpecialFolder = not account?.get('draftMailbox')? or
               not account?.get('sentMailbox')? or
               not account?.get('trashMailbox')?

        needSpecialFolder = action in [
            'account.mailbox.messages'
            'message'
            'conversation'
            'compose'
            'edit'
        ]

        if account? and noSpecialFolder and needSpecialFolder
            @redirect
                direction: 'first'
                action: 'account.config'
                parameters: [ account.get('id'), 'mailboxes']
                fullWidth: true
            LayoutActionCreator.alertError t 'account no special mailboxes'


    componentWillUnmount: ->
        # Stops listening to router changes
        @props.router.off 'fluxRoute', @onRoute
