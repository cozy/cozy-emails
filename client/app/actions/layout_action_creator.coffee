XHRUtils = require '../utils/xhr_utils'
SocketUtils = require '../utils/socketio_utils'

LayoutStore  = require '../stores/layout_store'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'

AppDispatcher = require '../app_dispatcher'

{ActionTypes, AlertLevel, MessageFlags} = require '../constants/app_constants'

AccountActionCreator = require './account_action_creator'
SearchActionCreator = require './search_action_creator'

_cachedQuery = {}

module.exports = LayoutActionCreator =

    setDisposition: (type) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SET_DISPOSITION
            value: type

    # TODO: use a global method to DRY this 3-ones
    increasePreviewPanel: (factor = 1) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RESIZE_PREVIEW_PANE
            value: Math.abs factor

    decreasePreviewPanel: (factor = 1) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RESIZE_PREVIEW_PANE
            value: -1 * Math.abs factor

    resetPreviewPanel: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RESIZE_PREVIEW_PANE
            value: null

    toggleFullscreen: ->
        type = if LayoutStore.isPreviewFullscreen()
            ActionTypes.MINIMIZE_PREVIEW_PANE
        else
            ActionTypes.MAXIMIZE_PREVIEW_PANE

        AppDispatcher.handleViewAction
            type: type

    minimizePreview: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.MINIMIZE_PREVIEW_PANE

    refresh: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.REFRESH
            value: null

    alert: (message) ->
        LayoutActionCreator.notify message,
            level: AlertLevel.INFO
            autoclose: true

    alertSuccess: (message) ->
        LayoutActionCreator.notify message,
            level: AlertLevel.SUCCESS
            autoclose: true

    alertWarning: (message) ->
        LayoutActionCreator.notify message,
            level: AlertLevel.WARNING
            autoclose: true

    alertError: (message) ->
        LayoutActionCreator.notify message,
            level: AlertLevel.ERROR
            autoclose: true

    notify: (message, options) ->
        if not message? or message.toString().trim() is ''
            # Throw an error to get the stack trace in server logs
            throw new Error 'Empty notification'
        else
            task =
                id: Date.now()
                finished: true
                message: message.toString()

            if options?
                task.autoclose = options.autoclose
                task.errors = options.errors
                task.finished = options.finished
                task.actions = options.actions
                task.level = options.level

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
            AppDispatcher.handleViewAction
                type: ActionTypes.MESSAGE_FETCH_REQUEST
                value: {mailboxID, query}

            updated = Date.now()
            XHRUtils.fetchMessagesByFolder mailboxID, query, (err, rawMsg) ->
                if err?
                    AppDispatcher.handleViewAction
                        type: ActionTypes.MESSAGE_FETCH_FAILURE
                        value: {mailboxID, query}
                else
                    # This prevent to override local updates with older ones
                    # from server
                    rawMsg.messages.forEach (msg) ->
                        msg.updated = updated
                    AppDispatcher.handleViewAction
                        type: ActionTypes.MESSAGE_FETCH_SUCCESS
                        value: {mailboxID, query, fetchResult: rawMsg}

    # Apply filters and sort criteria on message list then display it
    showFilteredList: (filter, sort) ->
        @filterMessages filter
        @sortMessages sort

        params           = _.clone(MessageStore.getParams())
        params.accountID = AccountStore.getSelected().get 'id'
        params.mailboxID = AccountStore.getSelectedMailbox().get 'id'
        @showMessageList parameters: params

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

        length = MessageStore.getConversationsLength().get(conversationID)
        if length? and length > 1
            MessageActionCreator.fetchConversation conversationID


    showComposeNewMessage: (panelInfo, direction) ->
        # if there isn't a selected account (page loaded directly),
        # select the default account
        selectedAccount = AccountStore.getSelected()
        if not selectedAccount?
            defaultAccount = AccountStore.getDefault()
            AccountActionCreator.selectAccount defaultAccount.get 'id'


    # Display compose widget but this time it's aimed to be pre-filled:
    # either with reply/forward or with draft information.
    showComposeMessage: (panelInfo, direction) ->
        # if there isn't a selected account (page loaded directly),
        # select the default account
        selectedAccount = AccountStore.getSelected()
        if not selectedAccount?
            defaultAccount = AccountStore.getDefault()
            AccountActionCreator.selectAccount defaultAccount.get 'id'

        # If message is not there, it fetches it from server.
        messageID = panelInfo.parameters.messageID
        message = MessageStore.getByID messageID
        unless message?
            XHRUtils.fetchMessage messageID, (err, rawMessage) ->
                if err?
                    LayoutActionCreator.alertError err
                else
                    MessageActionCreator.receiveRawMessage rawMessage


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

    toastsShow: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.TOASTS_SHOW

    toastsHide: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.TOASTS_HIDE

    intentAvailability: (availability) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.INTENT_AVAILABLE
            value: availability

    # Drawer
    drawerShow: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.DRAWER_SHOW

    drawerHide: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.DRAWER_HIDE

    drawerToggle: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.DRAWER_TOGGLE

    displayModal: (params) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.DISPLAY_MODAL
            value: params

    hideModal: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.HIDE_MODAL

# circular import, require after
MessageActionCreator = require './message_action_creator'
