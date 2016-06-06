require '../styles/application.styl'
require '../../vendor/aria-tips/aria-tips.css'

React = require 'react'
{div, section, main, h1, img, p} = React.DOM
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
RequestsStore        = require '../stores/requests_store'
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
        StoreWatchMixin [SettingsStore, RequestsStore, RouterStore]
    ]

    getStateFromStores: (props) ->
        previewSize = LayoutGetter.getPreviewSize()
        className = "layout layout-column layout-preview-#{previewSize}"

        if (mailbox = RouterGetter.getMailbox())
            return {
                mailboxID       : (mailboxID = RouterGetter.getMailboxID())
                accountID       : RouterGetter.getAccountID()
                conversationID  : RouterGetter.getConversationID()
                messageID       : RouterGetter.getMessageID()
                subject         : RouterGetter.getSubject()
                action          : RouterGetter.getAction()
                isEditable      : RouterGetter.isEditable()
                modal           : RouterGetter.getModal()
                className       : className
                messages        : RouterGetter.getMessagesList mailboxID
                conversation    : RouterGetter.getConversation()
                isMailbox       : RouterGetter.isMailboxExist()
                isLoading       : RouterGetter.isMailboxLoading()
                isIndexing      : RouterGetter.isMailboxIndexing()
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
        if @state.isIndexing
            return div className: 'reindexing-message',
                img
                    className: 'spinner'
                    src: "img/spinner.svg"
                h1 null,
                    'We need to reindex your emails.'
                p null,
                    'This page will refresh in a minute.'

        action = MessageActions.CREATE
        composeURL = RouterGetter.getURL {action}

        action = AccountActions.CREATE
        newAccountURL = RouterGetter.getURL {action}

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
                    nbUnread        : RouterGetter.getUnreadLength()
                    nbFlagged       : RouterGetter.getFlaggedLength()


                main null,
                    div
                        className: 'panels',

                        if @state.isMailbox
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
                                conversationID  : @state.conversationID
                                subject         : @state.subject
                                messages        : @state.conversation

                        else
                            section
                                'key'          : 'placeholder'
                                'aria-expanded': false


            if @state.action is AccountActions.CREATE
                AccountWizardCreation
                    key: 'modal-account-wizard'
                    hasDefaultAccount: RouterGetter.getAccountID()?


            # Display feedback
            Modal @state.modal if @state.modal?


            ToastContainer()


            # Tooltips' content is declared once at the application level.
            # It's hidden so it doesn't break the layout. Other components
            # can then reference the tooltips by their ID to trigger them.
            Tooltips key: "tooltips"
