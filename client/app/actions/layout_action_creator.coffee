XHRUtils = require '../utils/xhr_utils'

AccountStore  = require '../stores/account_store'
LayoutStore   = require '../stores/layout_store'
MessageStore  = require '../stores/message_store'

AppDispatcher = require '../app_dispatcher'

{ActionTypes, AlertLevel, NotifyType} = require '../constants/app_constants'

AccountActionCreator = require './account_action_creator'
MessageActionCreator = require './message_action_creator'
SearchActionCreator = require './search_action_creator'

_cachedQuery = {}

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

    alertHide: (level, message) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.HIDE_ALERT

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
            task.errors    = options.errors
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

    showMessageList: (panelInfo) ->
        LayoutActionCreator.hideReponsiveMenu()

        {accountID, mailboxID} = panelInfo.parameters
        selectedAccount = AccountStore.getSelected()
        if not selectedAccount? or selectedAccount.get('id') isnt accountID
            AccountActionCreator.selectAccount accountID

        cached = _cachedQuery.mailboxID is mailboxID
        query = {}
        ['sort', 'after', 'before', 'flag', 'pageAfter'].forEach (param) ->
            value = panelInfo.parameters[param]
            if value? and value isnt ''
                query[param] = value
                if _cachedQuery[param] isnt value
                    _cachedQuery[param] = value
                    cached = false
        _cachedQuery.mailboxID = mailboxID

        if not cached
            XHRUtils.fetchMessagesByFolder mailboxID, query, (err, rawMessages) ->
                if err?
                    LayoutActionCreator.alertError err
                else
                    MessageActionCreator.receiveRawMessages rawMessages

    showMessage: (panelInfo, direction) ->
        onMessage = (msg) ->
            # if there isn't a selected account (page loaded directly),
            # select the message's account
            selectedAccount = AccountStore.getSelected()
            if  not selectedAccount? and msg?.mailbox
                AccountActionCreator.selectAccount rawMessage.mailbox
        LayoutActionCreator.hideReponsiveMenu()
        messageID = panelInfo.parameters.messageID
        message = MessageStore.getByID messageID
        if message?
            onMessage message
        else
            XHRUtils.fetchMessage messageID, (err, rawMessage) ->

                if err?
                    LayoutActionCreator.alertError err
                else
                    MessageActionCreator.receiveRawMessage rawMessage
                    onMessage rawMessage

    showConversation: (panelInfo, direction) ->
        onMessage = (msg) ->
            # if there isn't a selected account (page loaded directly),
            # select the message's account
            selectedAccount = AccountStore.getSelected()
            if  not selectedAccount? and msg?.mailbox
                AccountActionCreator.selectAccount rawMessage.mailbox
        LayoutActionCreator.hideReponsiveMenu()
        messageID      = panelInfo.parameters.messageID
        message        = MessageStore.getByID messageID
        if message?
            onMessage message
            conversationID = message.get 'conversationID'
            XHRUtils.fetchConversation conversationID, (err, rawMessages) ->

                if err?
                    LayoutActionCreator.alertError err
                else
                    MessageActionCreator.receiveRawMessages rawMessages
                    onMessage rawMessages[0]
        else
            XHRUtils.fetchMessage messageID, (err, rawMessage) ->

                if err?
                    LayoutActionCreator.alertError err
                else
                    MessageActionCreator.receiveRawMessage rawMessage
                    onMessage rawMessage


    showComposeNewMessage: (panelInfo, direction) ->
        LayoutActionCreator.hideReponsiveMenu()

        # if there isn't a selected account (page loaded directly),
        # select the default account
        selectedAccount = AccountStore.getSelected()
        if not selectedAccount?
            defaultAccount = AccountStore.getDefault()
            AccountActionCreator.selectAccount defaultAccount.get 'id'

    # Edit draft
    showComposeMessage: (panelInfo, direction) ->
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
                MessageActionCreator.receiveRawMessages null
                LayoutActionCreator.notify t('account refreshed'),
                    autoclose: true

