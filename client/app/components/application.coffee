require '../styles/application.styl'
require '../../vendor/aria-tips/aria-tips.css'

React = require 'react'

# React components
Layout = require './layout'

# React Mixins
RouterAC  = require '../actions/router_action_creator'
ContactActionCreator = require '../actions/contact_action_creator'
AccountActionCreator = require '../actions/account_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator  = require '../actions/message_action_creator'
NotificationActionCreator = require '../actions/notification_action_creator'

RouterGetter = require '../getters/router'
MessageGetter = require '../getters/messages'
LayoutGetter = require '../getters/layout'
SelectionGetter = require '../getters/selection'
RequestsGetter = require '../getters/requests'
ContactGetter = require '../getters/contact'

{Provider, connect} = require('react-redux')


###
    This component is the root of the React tree.
    It listens to the store and re-render
###

bindStore = connect(
    # MapStateToProps
    (state) ->
        # Store
        action                  : RouterGetter.getAction(state)
        hasAccounts             : RouterGetter.hasAccounts(state)
        accounts                : RouterGetter.getAllAccounts(state)
        accountID               : RouterGetter.getAccountID(state)
        messageID               : RouterGetter.getMessageID(state)
        trashboxID              : RouterGetter.getTrashBoxID(state)

        # Selection
        isAllSelected           : SelectionGetter.isAllSelected(state)
        selection               : SelectionGetter.getSelection(state)

        # URL
        composeURL              : RouterGetter.getComposeURL(state)
        newAccountURL           : RouterGetter.getCreateAccountURL(state)

        # Mailbox
        mailboxID               : RouterGetter.getMailboxID(state)
        isTrashbox              : RouterGetter.isTrashbox(state)
        nbUnread                : RouterGetter.getUnreadLength(state)
        nbFlagged               : RouterGetter.getFlaggedLength(state)

        # Conversation
        conversationID          : RouterGetter.getConversationID(state)
        conversation            : RouterGetter.getConversation(state)
        subject                 : RouterGetter.getSubject(state)
        contacts                : ContactGetter.getAll(state)
        messages                : RouterGetter.getMessagesListWithIsDeleted(state)
        emptyMessages           : RouterGetter.getEmptyMessage(state)

        # MessageList Container
        hasNextPage             : RouterGetter.hasNextPage(state)
        previewSize             : LayoutGetter.getPreviewSize(state)

        # Modal Container
        modal                   : RouterGetter.getModal(state)

        # Account
        login                   : RouterGetter.getLogin(state)

        # Notifications
        toasts                  : RouterGetter.getToasts(state)
        toastsHidden            : LayoutGetter.isToastHidden(state)

        # Metrics about loading
        lastSync                : RouterGetter.getLastSync(state)
        isLoading               : RequestsGetter.isRefreshing(state)
        isIndexing              : RouterGetter.isMailboxIndexing(state)
        hasSettingsChanged      : RouterGetter.hasSettingsChanged(state)
        conversationsLengths    : MessageGetter.getConversationsLengths(state)
        isConversationLoading   : RequestsGetter.isConversationLoading(state)
        isMailboxLoading        : RouterGetter.isMailboxLoading(state)
        isRefreshError          : RequestsGetter.isRefreshError(state)
        isRequestError          : RequestsGetter.isRequestError(state)


    # MapDispatchToProps
    (dispatch) ->
        # Account: creation
        doAccountDiscover     : AccountActionCreator(dispatch).discover
        doAccountCheck        : AccountActionCreator(dispatch).check

        # Messages
        doCreateContact       : ContactActionCreator(dispatch).createContact

        # Modal container
        displayModal          : LayoutActionCreator(dispatch).displayModal
        doCloseModal          : RouterAC.closeModal.bind(RouterAC, dispatch)

        # Messages
        onLoadMore            : RouterAC.loadMore.bind(RouterAC, dispatch)
        doDisplayImages       : MessageActionCreator(dispatch).displayImages
        doDeleteMessage       : MessageActionCreator(dispatch).deleteMessage
        doCloseConversation   : RouterAC.closeConversation.bind(RouterAC, dispatch)
        doMarkMessage         : RouterAC.markMessage.bind(RouterAC, dispatch)
        doGotoMessage         : RouterAC.gotoMessage.bind(RouterAC, dispatch)
        gotoConversation      : RouterAC.gotoConversation.bind(RouterAC, dispatch)

        # Notifications
        toastsShow            : LayoutActionCreator(dispatch).toastsShow
        toastsHide            : LayoutActionCreator(dispatch).toastsHide
        clearToasts           : LayoutActionCreator(dispatch).clearToasts
        doDeleteToast         : NotificationActionCreator(dispatch).taskDelete
)

Layout = React.createFactory bindStore Layout

module.exports = React.createClass
    displayName: 'Application'

    render: ->
        React.createElement Provider, store: @props.store,
            React.createElement Layout
