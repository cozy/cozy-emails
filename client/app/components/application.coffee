require '../styles/application.styl'

React = require 'react'
{div, section, main} = React.DOM

# React components
Menu            = React.createFactory require './menu'
Modal           = React.createFactory require './modal'
ToastContainer  = React.createFactory require './toast_container'
Tooltips        = React.createFactory require './tooltips-manager'
MessageList     = React.createFactory require './message-list'
Conversation    = React.createFactory require './conversation'
AccountConfig   = React.createFactory require './account_config'
Compose         = React.createFactory require './compose'

# React Mixins
RouterStore          = require '../stores/router_store'
SettingsStore        = require '../stores/settings_store'
RefreshesStore       = require '../stores/refreshes_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'
TooltipRefesherMixin = require '../mixins/tooltip_refresher_mixin'

RouterGetter = require '../getters/router'
SelectionGetter = require '../getters/selection'

{MessageActions, AccountActions} = require '../constants/app_constants'

###
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly
###

module.exports = React.createClass
    displayName: 'Application'

    mixins: [
        TooltipRefesherMixin
        StoreWatchMixin [SettingsStore, RefreshesStore, RouterStore]
    ]

    getStateFromStores: (props) ->
        settings = RouterGetter.getLayoutSettings()
        className = ['layout'
            "layout-#{settings.disposition}"
            if settings.isCompact then "layout-compact"
            "layout-preview-#{settings.previewSize}"].join(' ')

        if (mailbox = RouterGetter.getCurrentMailbox())
            return {
                mailboxID       : (mailboxID = mailbox?.get 'id')
                accountID       : RouterGetter.getAccountID()
                messageID       : RouterGetter.getCurrentMessageID()
                action          : RouterGetter.getAction()
                isEditable      : RouterGetter.isEditable()
                modal           : RouterGetter.getModal()
                className       : className
                messages        : RouterGetter.getMessagesList mailboxID
                conversation    : RouterGetter.getConversation()
                isMailbox       : mailbox.get('lastSync')?
                isLoading       : RouterGetter.isMailboxLoading()
            }

        return {
            action          : RouterGetter.getAction()
            modal           : RouterGetter.getModal()
            className       : className
        }


    render: ->
        action = MessageActions.CREATE
        composeURL = RouterGetter.getURL {action}

        action = AccountActions.CREATE
        newAccountURL = RouterGetter.getURL {action}

        isAccount = -1 < @state.action?.indexOf 'account'

        message = RouterGetter.getMessage()

        isCompact = SettingsStore.get('listStyle') is 'compact'

        div className: @state.className,
            div className: 'app',
                Menu
                    ref             : 'menu'
                    key             : 'menu-' + @state.accountID
                    accountID       : @state.accountID
                    mailboxID       : @state.mailboxID
                    accounts        : RouterGetter.getAccounts()?.toArray()
                    composeURL      : composeURL
                    newAccountURL   : newAccountURL
                    mailboxes       : RouterGetter.getMailboxes()

                main
                    className: @props.layout

                    if isAccount
                        accountID = @state.accountID or 'new'
                        tab = RouterGetter.getSelectedTab()
                        key = "account-config-#{accountID}-#{tab}"
                        AccountConfig {key, accountID, tab}

                    else if @state.isEditable
                        Compose
                            ref                  : "compose-#{@state.action}-#{@state.messageID}"
                            key                  : "compose-#{@state.action}-#{@state.messageID}"
                            id                   : @state.messageID
                            action               : @state.action
                            message              : message
                            inReplyTo            : RouterGetter.getReplyMessage @state.messageID
                            settings             : SettingsStore.get()
                            account              : RouterGetter.getAccount()

                    else
                        div
                            className: 'panels'
                            MessageList
                                ref             : "messageList"
                                key             : "messageList-#{@state.mailboxID}"
                                accountID       : @state.accountID
                                mailboxID       : @state.mailboxID
                                messageID       : @state.messageID
                                messages        : @state.messages
                                emptyMessages   : RouterGetter.getEmptyMessage()
                                isCompact       : isCompact
                                isAllSelected   : SelectionGetter.isAllSelected()
                                selection       : SelectionGetter.getSelection @state.messages
                                hasNextPage     : RouterGetter.hasNextPage()
                                isMailbox       : @state.isMailbox
                                isLoading       : @state.isLoading

                            if @state.isMailbox and @state.messageID
                                Conversation
                                    ref             : "conversation"
                                    key             : "conversation-#{@state.messageID}"
                                    messageID       : @state.messageID
                                    conversationID  : message?.get 'conversationID'
                                    subject         : message?.get 'subject'
                                    conversation    : @state.conversation
                            else
                                section
                                    'key'          : 'placeholder'
                                    'aria-expanded': false

            # Display feedback
            Modal @state.modal if @state.modal?

            ToastContainer()

            # Tooltips' content is declared once at the application level.
            # It's hidden so it doesn't break the layout. Other components
            # can then reference the tooltips by their ID to trigger them.
            Tooltips key: "tooltips"
