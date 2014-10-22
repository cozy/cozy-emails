XHRUtils = require '../utils/xhr_utils'

AccountStore  = require '../stores/account_store'
LayoutStore   = require '../stores/layout_store'

AppDispatcher = require '../app_dispatcher'

{ActionTypes, AlertLevel, NotifyType} = require '../constants/app_constants'

AccountActionCreator = require './account_action_creator'
MessageActionCreator = require './message_action_creator'
SearchActionCreator = require './search_action_creator'

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

    refresh: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.REFRESH
            value: null

    alertSuccess: (message) ->
        LayoutActionCreator.alert AlertLevel.SUCCESS, message
    alertInfo:    (message) ->
        LayoutActionCreator.alert AlertLevel.INFO, message
    alertWarning: (message) ->
        LayoutActionCreator.alert AlertLevel.WARNING, message
    alertError:   (message) ->
        LayoutActionCreator.alert AlertLevel.ERROR, message
    notify: (message, options) ->
        task =
            id: Date.now()
            type: NotifyType.CLIENT
            finished: true
            message: message
        if options?
            task.autoclose = options.autoclose
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_TASK_UPDATE
            value: task

    filterMessages: (filter) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.LIST_FILTER
            value: filter

    quickFilterMessages: (filter) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.LIST_QUICK_FILTER
            value: filter

    sortMessages: (sort) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.LIST_SORT
            value: sort

    getDefaultRoute: ->
        # if there is no account, we display the configAccount
        if AccountStore.getAll().length is 0 then 'account.new'
        # else go directly to first account
        else 'account.mailbox.messages'

    showMessageList: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()

        {accountID, mailboxID, page} = panelInfo.parameters
        selectedAccount = AccountStore.getSelected()
        if not selectedAccount? or selectedAccount.get('id') isnt accountID
            AccountActionCreator.selectAccount accountID

        XHRUtils.fetchMessagesByFolder mailboxID, page, (err, rawMessage) ->
            if err?
                LayoutActionCreator.alertError err
            else
                MessageActionCreator.receiveRawMessages rawMessage

    showConversation: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        messageID = panelInfo.parameters.messageID
        XHRUtils.fetchConversation messageID, (err, rawMessage) ->

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
        AccountActionCreator.selectAccount null

    showConfigAccount: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()
        AccountActionCreator.selectAccount panelInfo.parameters.accountID

    showSearch: (panelInfo, direction) ->
        AccountActionCreator.selectAccount null

        {query, page} = panelInfo.parameters

        SearchActionCreator.setQuery query

        XHRUtils.search query, page, (err, results) ->
            if err?
                console.log err
            else
                SearchActionCreator.receiveRawSearchResults results

    showSettings: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()


    refreshMessages: ->
        XHRUtils.refresh (results) ->
            if results is "done"
                LayoutActionCreator.notify t('account refreshed'), autoclose: true

