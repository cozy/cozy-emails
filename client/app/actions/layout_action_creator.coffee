XHRUtils = require '../utils/xhr_utils'
SocketUtils = require '../utils/socketio_utils'

React     = require 'react'
ReactDOM  = require 'react-dom'

LayoutStore  = require '../stores/layout_store'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'
ApplicationGetters = require '../getters/application'

AppDispatcher = require '../app_dispatcher'

{ActionTypes, AlertLevel, MessageFlags} = require '../constants/app_constants'

AccountActionCreator = require './account_action_creator'
MessageActionCreator = require './message_action_creator'

uniqID = 0

module.exports = LayoutActionCreator =

    setRoute: (value) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SET_ROUTE
            value: value

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

    toggleFullscreen: (value) ->
        # Get contextual value if
        # no value is in arguments
        unless typeof value is 'boolean'
            value = not LayoutStore.isPreviewFullscreen()

        type = if value
            ActionTypes.MAXIMIZE_PREVIEW_PANE
        else
            ActionTypes.MINIMIZE_PREVIEW_PANE

        AppDispatcher.handleViewAction
            type: type

    focus: (path) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.FOCUS
            value: path

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
        else 'message.list'

    showMessageList: (data) ->
        {accountID, mailboxID, messageID, params} = data
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

        # FIXME : normalement,
        # ça devrait sauvegarder les filtres
        # Vérifier
        # FIXME : faire fonctionner
        # avec 'params' en argument
        params =
            pageAfter: '-'
            sort: '-date'
            after: '-'
            before: '-'
            type: 'nofilter'
            flag: '-'
        # Get Messages first
        unless MessageStore.getCurrentConversation()
            AppDispatcher.handleViewAction
                type: ActionTypes.MESSAGE_FETCH_REQUEST
            AppDispatcher.waitFor[MessageStore.dispatchToken]

        # Display Application
        Application = React.createFactory require '../components/application'
        props = ApplicationGetters.getProps 'application'
        ReactDOM.render Application(props), document.querySelector '[role=application]'


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
