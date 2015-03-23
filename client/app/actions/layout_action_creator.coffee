XHRUtils = require '../utils/xhr_utils'
SocketUtils = require '../utils/socketio_utils'

AccountStore  = require '../stores/account_store'
LayoutStore   = require '../stores/layout_store'
MessageStore  = require '../stores/message_store'

AppDispatcher = require '../app_dispatcher'

{ActionTypes, AlertLevel, MessageFlags} = require '../constants/app_constants'

AccountActionCreator = require './account_action_creator'
MessageActionCreator = require './message_action_creator'
SearchActionCreator = require './search_action_creator'

_cachedQuery = {}
_cachedDisposition = null

module.exports = LayoutActionCreator =

    setDisposition: (type, value) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SET_DISPOSITION
            value:
                type: type
                value: value

    toggleFullscreen: ->
        if _cachedDisposition?
            AppDispatcher.handleViewAction
                type: ActionTypes.SET_DISPOSITION
                value:
                    disposition: _cachedDisposition
            _cachedDisposition = null
        else
            _cachedDisposition = _.clone LayoutStore.getDisposition()
            AppDispatcher.handleViewAction
                type: ActionTypes.SET_DISPOSITION
                value:
                    type: _cachedDisposition.type
                    value: 0

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
            finished: true
            message: message
        if options?
            task.autoclose = options.autoclose
            task.errors    = options.errors
            task.finished  = options.finished
            task.actions   = options.actions
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_TASK_UPDATE
            value: task

    clearToasts: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.CLEAR_TOASTS
            value: null

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
        {accountID, mailboxID} = panelInfo.parameters
        selectedAccount = AccountStore.getSelected()
        selectedMailbox = AccountStore.getSelectedMailbox()
        if not selectedAccount? or
        selectedAccount.get('id') isnt accountID or
        selectedMailbox.get('id') isnt mailboxID
            AccountActionCreator.selectAccount accountID, mailboxID

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
            MessageActionCreator.setFetching true
            XHRUtils.fetchMessagesByFolder mailboxID, query, (err, rawMsg) ->
                MessageActionCreator.setFetching false
                if err?
                    LayoutActionCreator.alertError err
                else
                    MessageActionCreator.receiveRawMessages rawMsg

    showMessage: (panelInfo, direction) ->
        onMessage = (msg) ->
            # if there isn't a selected account (page loaded directly),
            # select the message's account
            selectedAccount = AccountStore.getSelected()
            if  not selectedAccount? and msg?.accountID
                AccountActionCreator.selectAccount msg.accountID
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
            if  not selectedAccount? and msg?.accountID
                AccountActionCreator.selectAccount msg.accountID
        messageID      = panelInfo.parameters.messageID
        conversationID = panelInfo.parameters.conversationID
        message        = MessageStore.getByID messageID
        if message?
            onMessage message
        XHRUtils.fetchConversation conversationID, (err, rawMessages) ->

            if err?
                LayoutActionCreator.alertError err
            else
                # prevent flashing of message in message list when first
                # marking as read a new message. If it has been flagged Seen
                # in local cache but not on server, ignore server value
                if rawMessages.length is 1
                    message = MessageStore.getByID rawMessages[0].id
                    if message? and
                       rawMessages[0].flags.length is 0 and
                       message.get('flags').length is 1 and
                       message.get('flags')[0] is MessageFlags.SEEN
                        rawMessages[0].flags = MessageFlags.SEEN
                MessageActionCreator.receiveRawMessages rawMessages
                onMessage rawMessages[0]

    showComposeNewMessage: (panelInfo, direction) ->
        # if there isn't a selected account (page loaded directly),
        # select the default account
        selectedAccount = AccountStore.getSelected()
        if not selectedAccount?
            defaultAccount = AccountStore.getDefault()
            AccountActionCreator.selectAccount defaultAccount.get 'id'

    # Edit draft
    showComposeMessage: (panelInfo, direction) ->
        # if there isn't a selected account (page loaded directly),
        # select the default account
        selectedAccount = AccountStore.getSelected()
        if not selectedAccount?
            defaultAccount = AccountStore.getDefault()
            AccountActionCreator.selectAccount defaultAccount.get 'id'

    showCreateAccount: (panelInfo, direction) ->
        AccountActionCreator.selectAccount null

    showConfigAccount: (panelInfo, direction) ->
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


    refreshMessages: ->
        XHRUtils.refresh true, (err, results) ->
            if err?
                console.log err
                LayoutActionCreator.notify t('account refresh error'),
                    autoclose: false
                    finished: true
                    errors: [ JSON.stringify err ]
            else
                if results is "done"
                    MessageActionCreator.receiveRawMessages null
                    LayoutActionCreator.notify t('account refreshed'),
                        autoclose: true

    toastsShow: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.TOASTS_SHOW

    toastsHide: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.TOASTS_HIDE

