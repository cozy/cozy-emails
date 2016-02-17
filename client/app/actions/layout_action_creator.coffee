XHRUtils = require '../utils/xhr_utils'
SocketUtils = require '../utils/socketio_utils'

LayoutStore  = require '../stores/layout_store'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'

AppDispatcher = require '../app_dispatcher'

{ActionTypes, AlertLevel, MessageFlags} = require '../constants/app_constants'

AccountActionCreator = require './account_action_creator'
MessageActionCreator = require './message_action_creator'

uniqID = 0

module.exports = LayoutActionCreator =

    setDisposition: (type) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SET_DISPOSITION
            value: type

    toggleListMode: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.TOGGLE_LIST_MODE

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
                id: "taskid-#{uniqID++}"
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

    getDefaultRoute: ->
        # if there is no account, we display the configAccount
        if AccountStore.getAll().size is 0 then 'account.new'
        # else go directly to first account
        else 'account.mailbox.messages'

    showMessageList: (panelInfo) ->
        params = panelInfo.parameters
        {accountID, mailboxID, filter, sort, before, after} = params

        # ensure the proper account is selected
        AccountActionCreator.ensureSelected accountID, mailboxID

        AppDispatcher.handleViewAction
            type: ActionTypes.QUERY_PARAMETER_CHANGED
            value: params

    showSearchResult: (panelInfo) ->
        {accountID, search} = panelInfo.parameters

        if accountID isnt 'all'
            AccountActionCreator.ensureSelected accountID
        else
            AccountActionCreator.selectAccount null

        AppDispatcher.handleViewAction
            type: ActionTypes.SEARCH_PARAMETER_CHANGED
            value: {accountID, search}

        if search isnt '-'
            MessageActionCreator.fetchSearchResults accountID, search

    showMessage: (panelInfo, direction) ->
        {messageID} = panelInfo.parameters

        message = MessageStore.getByID messageID
        if message?
            AccountActionCreator.selectAccountForMessage message
        else
            XHRUtils.fetchMessage messageID, (err, rawMessage) ->

                if err?
                    LayoutActionCreator.alertError err
                else
                    MessageActionCreator.receiveRawMessage rawMessage
                    AccountActionCreator.selectAccountForMessage rawMessage

    showConversation: (panelInfo, direction) ->
        messageID      = panelInfo.parameters.messageID
        conversationID = panelInfo.parameters.conversationID
        message        = MessageStore.getByID messageID
        if message?
            AccountActionCreator.selectAccountForMessage message

        length = MessageStore.getConversationsLength().get(conversationID)
        if not length? or length > 1
            MessageActionCreator.fetchConversation conversationID


    showComposeNewMessage: (panelInfo, direction) ->
        AccountActionCreator.selectDefaultIfNoneSelected()

    # Display compose widget but this time it's aimed to be pre-filled:
    # either with reply/forward or with draft information.
    showComposeMessage: (panelInfo, direction) ->
        AccountActionCreator.selectDefaultIfNoneSelected()

        # If message is not there, it fetches it from server.
        messageID = panelInfo.parameters.messageID
        message = MessageStore.getByID messageID
        unless message?
            XHRUtils.fetchMessage messageID, (err, rawMessage) ->
                if err?
                    LayoutActionCreator.alertError err
                else
                    MessageActionCreator.receiveRawMessage rawMessage
                    AccountActionCreator.selectAccountForMessage rawMessage


    showCreateAccount: (panelInfo, direction) ->
        AccountActionCreator.selectAccount null

    showConfigAccount: (panelInfo, direction) ->
        AccountActionCreator.selectAccount panelInfo.parameters.accountID

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
        params.closeModal ?= -> LayoutActionCreator.hideModal()
        AppDispatcher.handleViewAction
            type: ActionTypes.DISPLAY_MODAL
            value: params

    hideModal: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.HIDE_MODAL
