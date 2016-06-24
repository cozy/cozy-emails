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
MessageStore         = require '../stores/message_store'
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
        StoreWatchMixin [SettingsStore, RequestsStore, RouterStore, MessageStore]
    ]

    getStateFromStores: (props) ->
        previewSize = LayoutGetter.getPreviewSize()
        className = "layout layout-column layout-preview-#{previewSize}"

        if (mailboxID = RouterGetter.getMailboxID())
            return {
                mailboxID               : mailboxID
                accountID               : RouterGetter.getAccountID()
                conversationID          : RouterGetter.getConversationID()
                conversationLength      : RouterGetter.getConversationLength()
                messageID               : RouterGetter.getMessageID()
                subject                 : RouterGetter.getSubject()
                action                  : RouterGetter.getAction()
                modal                   : RouterGetter.getModal()
                className               : className
                lastSync                : RouterGetter.getLastSync()
                isLoading               : RouterGetter.isMailboxLoading()
                isConversationLoading   : RouterGetter.isConversationLoading()
                isIndexing              : RouterGetter.isMailboxIndexing()
                hasNextPage             : RouterGetter.hasNextPage()
                hasSettingsChanged      : RouterGetter.hasSettingsChanged()
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

        div className: @state.className,
            div className: 'app',
                Menu
                    ref             : 'menu'
                    key             : 'menu-' + @state.accountID
                    accountID       : @state.accountID
                    mailboxID       : @state.mailboxID
                    accounts        : RouterGetter.getAccounts()?.toArray()
                    composeURL      : RouterGetter.getComposeURL()
                    newAccountURL   : RouterGetter.getCreateAccountURL()
                    nbUnread        : RouterGetter.getUnreadLength()
                    nbFlagged       : RouterGetter.getFlaggedLength()

                main null,
                    div
                        className: 'panels',

                        if @state.lastSync?
                            MessageList
                                ref                 : "messageList"
                                key                 : "messageList-#{@state.mailboxID}-#{@state.conversationLength}"
                                accountID           : @state.accountID
                                mailboxID           : @state.mailboxID
                                conversationID      : @state.conversationID
                                messages            : (messages = RouterGetter.getMessagesList())
                                emptyMessages       : RouterGetter.getEmptyMessage()
                                isAllSelected       : SelectionGetter.isAllSelected()
                                selection           : SelectionGetter.getSelection messages
                                hasNextPage         : @state.hasNextPage
                                lastSync            : @state.lastSync
                                isLoading           : @state.isLoading

                        if @state.lastSync? and @state.messageID
                            Conversation
                                ref                     : "conversation"
                                key                     : "conversation-#{@state.messageID}"
                                messageID               : @state.messageID
                                conversationID          : @state.conversationID
                                subject                 : @state.subject
                                messages                : RouterGetter.getConversation()
                                isConversationLoading   : @state.isConversationLoading

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
