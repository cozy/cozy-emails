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
        # Create an account
        isAccountCreationBusy   : RequestsGetter.isAccountCreationBusy(state)
        isAccountDiscoverable   : RequestsGetter.isAccountDiscoverable(state)
        accountCreationAlert    : RequestsGetter.getAccountCreationAlert(state)
        isAccountOAuth          : RequestsGetter.isAccountOAuth(state)
        accountCreationSuccess  : RequestsGetter.getAccountCreationSuccess(state)?.account
        accountCreationDiscover : RequestsGetter.getAccountCreationDiscover(state)

        action                  : RouterGetter.getAction(state)
        hasAccounts             : RouterGetter.hasAccounts(state)
        modal                   : RouterGetter.getModal(state)
        mailboxID               : RouterGetter.getMailboxID(state)
        accounts                : RouterGetter.getAllAccounts(state)
        accountID               : RouterGetter.getAccountID(state)
        conversationID          : RouterGetter.getConversationID(state)
        messageID               : RouterGetter.getMessageID(state)
        subject                 : RouterGetter.getSubject(state)
        lastSync                : RouterGetter.getLastSync(state)
        isLoading               : RequestsGetter.isRefreshing(state)
        trashboxID              : RouterGetter.getTrashBoxID(state)
        isTrashbox              : RouterGetter.isTrashbox(state)
        isIndexing              : RouterGetter.isMailboxIndexing(state)
        hasNextPage             : RouterGetter.hasNextPage(state)
        isAllSelected           : SelectionGetter.isAllSelected(state)
        selection               : SelectionGetter.getSelection(state)
        messages                : RouterGetter.getMessagesListWithIsDeleted(state)
        emptyMessages           : RouterGetter.getEmptyMessage(state)
        composeURL              : RouterGetter.getComposeURL(state)
        newAccountURL           : RouterGetter.getCreateAccountURL(state)
        nbUnread                : RouterGetter.getUnreadLength(state)
        nbFlagged               : RouterGetter.getFlaggedLength(state)
        conversation            : RouterGetter.getConversation(state)
        previewSize             : LayoutGetter.getPreviewSize(state)
        toasts                  : RouterGetter.getToasts(state)
        toastsHidden            : LayoutGetter.isToastHidden(state)
        contacts                : ContactGetter.getAll(state)
        login                   : RouterGetter.getLogin(state)
        hasSettingsChanged      : RouterGetter.hasSettingsChanged(state)
        conversationsLengths    : MessageGetter.getConversationsLengths(state)
        isConversationLoading   : RequestsGetter.isConversationLoading(state)
        isMailboxLoading        : RouterGetter.isMailboxLoading(state)
        isRefreshError          : RequestsGetter.isRefreshError(state)


    # MapDispatchToProps
    (dispatch) ->
        onLoadMore            : RouterAC.loadMore.bind(RouterAC, dispatch)
        doCloseModal          : RouterAC.closeModal.bind(RouterAC, dispatch)

        doAccountDiscover     : AccountActionCreator(dispatch).discover
        doAccountCheck        : AccountActionCreator(dispatch).check

        doCreateContact       : ContactActionCreator(dispatch).createContact

        toastsShow            : LayoutActionCreator(dispatch).toastsShow
        toastsHide            : LayoutActionCreator(dispatch).toastsHide
        clearToasts           : LayoutActionCreator(dispatch).clearToasts
        displayModal          : LayoutActionCreator(dispatch).displayModal

        doDisplayImages       : MessageActionCreator.displayImages.bind(MessageActionCreator, dispatch)
        doDeleteMessage       : MessageActionCreator.deleteMessage.bind(MessageActionCreator, dispatch)

        doDeleteToast         : NotificationActionCreator(dispatch).taskDelete

        doCloseConversation   : RouterAC.closeConversation.bind(RouterAC, dispatch)
        doMarkMessage         : RouterAC.markMessage.bind(RouterAC, dispatch)

        doGotoMessage         : RouterAC.gotoMessage.bind(RouterAC, dispatch)
        gotoConversation      : RouterAC.gotoConversation.bind(RouterAC, dispatch)
)

Layout = React.createFactory bindStore Layout

module.exports = React.createClass
    displayName: 'Application'

    render: ->
        React.createElement Provider, store: @props.store,
            React.createElement Layout
