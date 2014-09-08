XHRUtils = require '../utils/XHRUtils'

AccountStore  = require '../stores/AccountStore'
LayoutStore   = require '../stores/LayoutStore'

AppDispatcher = require '../AppDispatcher'

{ActionTypes, AlertLevel} = require '../constants/AppConstants'

AccountActionCreator = require './AccountActionCreator'
MessageActionCreator = require './MessageActionCreator'
SearchActionCreator = require './SearchActionCreator'

module.exports = LayoutActionCreator =

    showReponsiveMenu: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SHOW_MENU_RESPONSIVE
            value: null

    hideReponsiveMenu: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.HIDE_MENU_RESPONSIVE
            value: null

    alert: (level, message) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.DISPLAY_ALERT
            value:
                level: level
                message: message

    alertSuccess: (message) -> LayoutActionCreator.alert AlertLevel.SUCCESS, message
    alertInfo:    (message) -> LayoutActionCreator.alert AlertLevel.INFO, message
    alertWarning: (message) -> LayoutActionCreator.alert AlertLevel.WARNING, message
    alertError:   (message) -> LayoutActionCreator.alert AlertLevel.ERROR, message

    showMessageList: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()

        accountID = panelInfo.parameters[0]
        mailboxID = panelInfo.parameters[1]
        AccountActionCreator.selectAccount accountID

        XHRUtils.fetchMessagesByFolder mailboxID, (err, rawMessage) ->
            if err?
                LayoutActionCreator.alertError err
            else
                MessageActionCreator.receiveRawMessages rawMessage

    showConversation: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        XHRUtils.fetchConversation panelInfo.parameters[0], (err, rawMessage) ->

            if err?
                LayoutActionCreator.alertError err
            else
                MessageActionCreator.receiveRawMessage rawMessage
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

    showSearch: (panelInfo, direction) ->
        AccountActionCreator.selectAccount -1

        [query, page] = panelInfo.parameters

        SearchActionCreator.setQuery query

        XHRUtils.search query, page, (err, results) ->
            if err?
                console.log err
            else
                SearchActionCreator.receiveRawSearchResults results

    showSettings: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()


