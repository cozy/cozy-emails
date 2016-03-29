XHRUtils = require '../utils/xhr_utils'
SocketUtils = require '../utils/socketio_utils'


LayoutStore  = require '../stores/layout_store'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'
SelectionStore = require '../stores/selection_store'

RouterStore = require '../stores/router_store'

AppDispatcher = require '../app_dispatcher'

{ActionTypes, MessageFlags} = require '../constants/app_constants'

AccountActionCreator = require './account_action_creator'
MessageActionCreator = require './message_action_creator'
RouterActionCreator = require './router_action_creator'

module.exports = LayoutActionCreator =

    setDisposition: (type) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SET_DISPOSITION
            value: type

    toggleListMode: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.TOGGLE_LIST_MODE

    selectAll: (value) ->
        type = ActionTypes.MAILBOX_SELECT_ALL
        AppDispatcher.handleViewAction {type}

    updateSelection: (value) ->
        type = ActionTypes.MAILBOX_SELECT
        AppDispatcher.handleViewAction {type, value}

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

    focus: (path) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.FOCUS
            value: path

    refresh: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.REFRESH
            value: null

    clearToasts: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.CLEAR_TOASTS
            value: null

    getDefaultRoute: ->
        # if there is no account, we display the configAccount
        if AccountStore.getAll().size is 0 then 'account.new'
        # else go directly to first account
        else 'message.list'

    updateMessageList: (params) ->
        {accountID, mailboxID, messageID, query} = params
        accountID ?= AccountStore.getSelectedOrDefault()?.get 'id'
        mailboxID ?= AccountStore.getSelectedMailbox()?.get 'id'

        unless accountID
            # TODO : si pas accountID
            # alors aller à la page de config
            console.log 'NO ACCOUNT FOUND'
            return

        # Select Mailbox
        AppDispatcher.handleViewAction
            type: ActionTypes.SELECT_ACCOUNT
            value: {accountID, mailboxID}

        # Set message as current
        if messageID
            AppDispatcher.handleViewAction
                type: ActionTypes.MESSAGE_CURRENT
                value: {messageID}

        if query
            AppDispatcher.handleViewAction
                type: ActionTypes.QUERY_PARAMETER_CHANGED
                value: {query}

        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_FETCH_REQUEST


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

    showMessage: (panelInfo) ->
        {messageID} = panelInfo.parameters
        return unless messageID

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

    # Display compose widget but this time it's aimed to be pre-filled:
    # either with reply/forward or with draft information.
    showComposeMessage: (panelInfo, direction) ->
        AccountActionCreator.selectDefaultIfNoneSelected()
        LayoutActionCreator.showMessage panelInfo

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

    displayModal: (params) ->
        params.closeModal ?= -> LayoutActionCreator.hideModal()
        AppDispatcher.handleViewAction
            type: ActionTypes.DISPLAY_MODAL
            value: params

    hideModal: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.HIDE_MODAL
