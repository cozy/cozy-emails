require '../styles/application.styl'
require '../../vendor/aria-tips/aria-tips.css'

React = require 'react'
{div, section, main} = React.DOM
AriaTips = require '../../vendor/aria-tips/aria-tips'

# React components
Menu                  = React.createFactory require './menu'
Modal                 = React.createFactory require './modal'
ToastContainer        = React.createFactory require './toast_container'
Tooltips              = React.createFactory require './tooltips-manager'
MessageList           = React.createFactory require './message-list'
Conversation          = React.createFactory require './conversation'
AccountConfig         = React.createFactory require './account_config'
Compose               = React.createFactory require './compose'
AccountWizardCreation = React.createFactory require './accounts/wizard/creation'

# React Mixins
RouterStore          = require '../stores/router_store'
SettingsStore        = require '../stores/settings_store'
RefreshesStore       = require '../stores/refreshes_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'

RouterGetter = require '../getters/router'
LayoutGetter = require '../getters/layout'
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
        StoreWatchMixin [SettingsStore, RefreshesStore, RouterStore]
    ]

    getStateFromStores: (props) ->
        previewSize = LayoutGetter.getPreviewSize()
        className = "layout layout-column layout-preview-#{previewSize}"

        if (mailbox = RouterGetter.getCurrentMailbox())
            return {
                mailboxID       : (mailboxID = mailbox?.get 'id')
                accountID       : RouterGetter.getAccountID()
                conversationID  : RouterGetter.getConversationID()
                messageID       : RouterGetter.getMessageID()
                action          : RouterGetter.getAction()
                isEditable      : RouterGetter.isEditable()
                modal           : RouterGetter.getModal()
                className       : className
                messages        : RouterGetter.getMessagesList mailboxID
                conversation    : RouterGetter.getConversation()
                isMailbox       : mailbox.get('lastSync')?
            }

        return {
            action          : RouterGetter.getAction()
            modal           : RouterGetter.getModal()
            className       : className
        }


    # AriaTips must bind the elements declared as tooltip to their
    # respective tooltip when the component is mounted (DOM elements exist).
    componentDidMount: ->
        AriaTips.bind()



    render: ->
        action = MessageActions.CREATE
        composeURL = RouterGetter.getURL {action}

        action = AccountActions.CREATE
        newAccountURL = RouterGetter.getURL {action}

        isAccount = -1 < @state.action?.indexOf 'account'

        message = RouterGetter.getMessage()

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
                    nbTotal         : RouterGetter.getTotalLength()
                    nbUnread        : RouterGetter.getUnreadLength()
                    nbRecent        : RouterGetter.getRecentLength()


                main
                    className: @props.layout

                    div
                        className: 'panels'
                        if RouterGetter.getAccounts().size
                            MessageList
                                ref             : "messageList"
                                key             : "messageList-#{@state.mailboxID}"
                                accountID       : @state.accountID
                                mailboxID       : @state.mailboxID
                                messages        : @state.messages
                                emptyMessages   : RouterGetter.getEmptyMessage()
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
                                messages        : @state.conversation
                        else
                            section
                                'key'          : 'placeholder'
                                'aria-expanded': false

            if @state.action is AccountActions.CREATE
                AccountWizardCreation
                    hasDefaultAccount: RouterGetter.getAccountID()?

            # Display feedback
            Modal @state.modal if @state.modal?

            ToastContainer()

            # Tooltips' content is declared once at the application level.
            # It's hidden so it doesn't break the layout. Other components
            # can then reference the tooltips by their ID to trigger them.
            Tooltips key: "tooltips"
