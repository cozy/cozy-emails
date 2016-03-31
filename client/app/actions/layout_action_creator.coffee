XHRUtils = require '../utils/xhr_utils'
SocketUtils = require '../utils/socketio_utils'

MessageStore = require '../stores/message_store'

RouterGetter = require '../getters/router'

AppDispatcher = require '../app_dispatcher'

{ActionTypes} = require '../constants/app_constants'

AccountActionCreator = require './account_action_creator'
MessageActionCreator = require './message_action_creator'

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

    clearToasts: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.CLEAR_TOASTS
            value: null

    updateMessageList: (params) ->
        {accountID, mailboxID, messageID, query} = params
        accountID ?= RouterGetter.getAccountID()
        mailboxID ?= RouterGetter.getMailboxID()

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
        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_CURRENT
            value: {messageID}

        if query
            AppDispatcher.handleViewAction
                type: ActionTypes.QUERY_PARAMETER_CHANGED
                value: {query}

        AppDispatcher.handleViewAction
            type: ActionTypes.MESSAGE_FETCH_REQUEST


    showSearchResult: (parameters) ->
        console.log 'showSearchResult', parameters
        # {accountID, search} = parameters
        #
        # if accountID isnt 'all'
        #     AccountActionCreator.ensureSelected accountID
        # else
        #     AccountActionCreator.selectAccount null
        #
        # AppDispatcher.handleViewAction
        #     type: ActionTypes.SEARCH_PARAMETER_CHANGED
        #     value: {accountID, search}
        #
        # if search isnt '-'
        #     MessageActionCreator.fetchSearchResults accountID, search

    saveMessage: (params) ->
        {accountID, mailboxID, messageID} = params
        accountID ?= RouterGetter.getAccountID()
        mailboxID ?= RouterGetter.getMailboxID()

        # Select Mailbox
        AppDispatcher.handleViewAction
            type: ActionTypes.SELECT_ACCOUNT
            value: {accountID, mailboxID}

        # Set message as current
        if messageID
            AppDispatcher.handleViewAction
                type: ActionTypes.MESSAGE_CURRENT
                value: {messageID}

            AppDispatcher.handleViewAction
                type: ActionTypes.MESSAGE_FETCH_REQUEST
                value: {messageID}

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
