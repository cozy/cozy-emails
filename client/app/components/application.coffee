require '../styles/application.styl'
require '../../vendor/aria-tips/aria-tips.css'

React = require 'react'
{div, section, main, h1, img, p} = React.DOM
AriaTips = require '../../vendor/aria-tips/aria-tips'

# React components
Menu                  = React.createFactory require './menu/menu'
Modal                 = React.createFactory require './modal'
ToastContainer        = React.createFactory require './toast_container'
Tooltips              = React.createFactory require './tooltips-manager'
MessageList           = React.createFactory require './message-list'
Conversation          = React.createFactory require './conversation'
AccountWizardCreation = React.createFactory require './accounts/wizard/creation'

# React Mixins
SettingsStore        = require '../stores/settings_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'

RouterActionCreator = require '../actions/router_action_creator'

RouterGetter = require '../getters/router'
LayoutGetter = require '../getters/layout'
SelectionGetter = require '../getters/selection'

{AccountActions} = require '../constants/app_constants'

###
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly
###

Application = React.createClass
    displayName: 'Application'

    # AriaTips must bind the elements declared as tooltip to their
    # respective tooltip when the component is mounted (DOM elements exist).
    componentDidMount: ->
        AriaTips.bind()


    render: ->
        if @props.isIndexing
            return div className: 'reindexing-message',
                img
                    className: 'spinner'
                    src: "img/spinner.svg"
                h1 null,
                    'We need to reindex your emails.'
                p null,
                    'This page will refresh in a minute.'

        div className: "layout layout-column layout-preview-#{@props.previewSize}",
            div className: 'app',
                Menu
                    ref             : 'menu'
                    key             : 'menu-' + @props.accountID
                    accountID       : @props.accountID
                    mailboxID       : @props.mailboxID
                    accounts        : @props.accounts
                    composeURL      : @props.composeURL
                    newAccountURL   : @props.newAccountURL
                    nbUnread        : @props.nbUnread
                    nbFlagged       : @props.nbFlagged

                main null,
                    div
                        className: 'panels',

                        if @props.lastSync?
                            MessageList
                                ref                 : "messageList"
                                key                 : "messageList-#{@props.mailboxID}-#{@props.conversationLength}"
                                accountID           : @props.accountID
                                mailboxID           : @props.mailboxID
                                conversationID      : @props.conversationID
                                messages            : @props.messages
                                emptyMessages       : @props.emptyMessages
                                isAllSelected       : @props.isAllSelected
                                selection           : @props.selection
                                hasNextPage         : @props.hasNextPage
                                lastSync            : @props.lastSync
                                isLoading           : @props.isLoading
                                onLoadMore          : @props.onLoadMore

                        if @props.lastSync? and @props.messageID
                            Conversation
                                ref                     : "conversation"
                                key                     : "conversation-#{@props.messageID}"
                                accountID               : @props.accountID
                                messageID               : @props.messageID
                                conversationID          : @props.conversationID
                                subject                 : @props.subject
                                messages                : @props.conversation
                                isConversationLoading   : @props.isConversationLoading

                        else
                            section
                                'key'          : 'placeholder'
                                'aria-expanded': false


            if @props.action is AccountActions.CREATE
                AccountWizardCreation
                    key: 'modal-account-wizard'
                    hasAccount: !!@props.accounts.size


            # Display feedback
            Modal @props.modal if @props.modal?


            ToastContainer()


            # Tooltips' content is declared once at the application level.
            # It's hidden so it doesn't break the layout. Other components
            # can then reference the tooltips by their ID to trigger them.
            Tooltips key: "tooltips"




# this component replace react-redux/connect while transitionning from stores
module.exports = React.createClass(
    displayName: 'StoreConnectedApplication'
    mixins: [
        StoreWatchMixin [SettingsStore]
    ]
    componentDidMount: ->
        store = require('../reducers/_store')
        @unsubscribe = store.subscribe @_setStateFromStores

    componentWillUnmount: ->
        @unsubscribe?()

    getStateFromStores: ->
        # state
        action                  : RouterGetter.getAction()
        modal                   : RouterGetter.getModal()
        mailboxID               : RouterGetter.getMailboxID()
        accounts                : RouterGetter.getAccounts()
        accountID               : RouterGetter.getAccountID()
        conversationID          : RouterGetter.getConversationID()
        conversationLength      : RouterGetter.getConversationLength()
        messageID               : RouterGetter.getMessageID()
        subject                 : RouterGetter.getSubject()
        lastSync                : RouterGetter.getLastSync()
        isLoading               : RouterGetter.isMailboxLoading()
        isConversationLoading   : RouterGetter.isConversationLoading()
        isIndexing              : RouterGetter.isMailboxIndexing()
        hasNextPage             : RouterGetter.hasNextPage()
        hasSettingsChanged      : RouterGetter.hasSettingsChanged()
        isAllSelected           : SelectionGetter.isAllSelected()
        selection               : SelectionGetter.getSelection()
        messages                : RouterGetter.getMessagesList()
        emptyMessages           : RouterGetter.getEmptyMessage()
        composeURL              : RouterGetter.getComposeURL()
        newAccountURL           : RouterGetter.getCreateAccountURL()
        nbUnread                : RouterGetter.getUnreadLength()
        nbFlagged               : RouterGetter.getFlaggedLength()
        conversation            : RouterGetter.getConversation()
        previewSize             : LayoutGetter.getPreviewSize()

        # events handler
        onLoadMore              : -> RouterActionCreator.loadMore()

    render: -> React.createElement Application, @state

)
