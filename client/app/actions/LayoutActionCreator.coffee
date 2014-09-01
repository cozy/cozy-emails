XHRUtils = require '../utils/XHRUtils'
AccountStore = require '../stores/AccountStore'
AppDispatcher = require '../AppDispatcher'
{ActionTypes} = require '../constants/AppConstants'
AccountActionCreator = require './AccountActionCreator'

module.exports = LayoutActionCreator =

    showReponsiveMenu: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SHOW_MENU_RESPONSIVE
            value: null

    hideReponsiveMenu: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.HIDE_MENU_RESPONSIVE
            value: null

    showMessageList: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()

        accountID = panelInfo.parameters[0]
        mailboxID = panelInfo.parameters[1]
        AccountActionCreator.selectAccount accountID

        XHRUtils.fetchMessagesByFolder mailboxID

    showConversation: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        XHRUtils.fetchConversation panelInfo.parameters[0], (err, rawMessage) ->

            # if there isn't a selected account (page loaded directly),
            # select the message's account
            selectedAccount = AccountStore.getSelected()
            if  not selectedAccount? and rawMessage?.mailbox
                AccountActionCreator.selectAccount rawMessage.mailbox


    showComposeNewMessage: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()

        # if there isn't a selected account (page loaded directly),
        # select the default account
        selectedAccount = AccountStore.getSelected()
        if not selectedAccount?
            defaultAccount = AccountStore.getDefault()
            AccountActionCreator.selectAccount defaultAccount.get 'id'

    showCreateAccount: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        AccountActionCreator.selectAccount -1

    showConfigAccount: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        AccountActionCreator.selectAccount panelInfo.parameters[0]
