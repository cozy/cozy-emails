_         = require 'underscore'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'
AccountStore = require '../stores/account_store'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes, AlertLevel} = require '../constants/app_constants'

class NotificationStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _uniqID = 0

    _tasks = Immutable.OrderedMap()

    getToasts: ->
        return _tasks

    alert: (message) ->
        @notify message,
            level: AlertLevel.INFO
            autoclose: true

    alertSuccess: (message) ->
        @notify message,
            level: AlertLevel.SUCCESS
            autoclose: true

    alertWarning: (message) ->
        @notify message,
            level: AlertLevel.WARNING
            autoclose: true

    alertError: (message) ->
        @notify message,
            level: AlertLevel.ERROR
            autoclose: true

    notify: (message, options) ->
        if not message? or message.toString().trim() is ''
            # Throw an error to get the stack trace in server logs
            throw new Error 'Empty notification'
        else
            task =
                id: "taskid-#{_uniqID++}"
                finished: true
                message: message.toString()

            if options?
                task.autoclose = options.autoclose
                task.errors = options.errors
                task.finished = options.finished
                task.actions = options.actions
                task.level = options.level

            _showNotification task

    ###
        Private API
    ###
    _removeNotification = (id) ->
        _tasks = _tasks.remove id

    _showNotification = (options) ->
        id = options.id or +Date.now()
        options.finished ?= true
        _tasks = _tasks.set id, Immutable.Map options
        if options.autoclose
            setTimeout _removeNotification.bind(@, id), 5000

    _makeMessage = (target, ref, actionAndOK, errMsg)->
        subject = target?.subject

        if target.messageID and target.isDraft
            type = 'draft'
        else if target.messageID
            type = 'message'
        else if target.conversationID
            type = 'conversation'
        else if target.conversationIDs
            type = 'conversations'
            smart_count = target.conversationIDs.length
        else if target.messageIDs
            type = 'messages'
            smart_count = target.messageIDs.length
        else
            throw new Error 'Wrong Usage : unrecognized target'

        return t "#{type} #{actionAndOK}",
            error: errMsg
            subject: subject or ''
            smart_count: smart_count

    _makeUndoAction = (ref) ->
        label: t 'action undo'
        onClick: -> getMessageActionCreator().undo ref

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.SETTINGS_UPDATE_FAILURE, ({error}) ->
            @alertError t('settings save error') + error

        handle ActionTypes.MAILBOX_CREATE_SUCCESS, ->
            @alertSuccess t("mailbox create ok")

        handle ActionTypes.MAILBOX_CREATE_FAILURE, ->
            message = "#{t("mailbox create ko")} #{error.message or error}"
            @alertError message

        handle ActionTypes.MAILBOX_UPDATE_SUCCESS, ->
            @alertSuccess t("mailbox update ok")

        handle ActionTypes.MAILBOX_UPDATE_FAILURE, ->
            message = "#{t("mailbox update ko")} #{error.message or error}"
            @alertError message

        handle ActionTypes.MAILBOX_EXPUNGE_SUCCESS, ->
            @alert t("mailbox expunge ok"), autoclose: true

        handle ActionTypes.MAILBOX_EXPUNGE_FAILURE, ({error, mailboxID, accountID}) ->
            @alertError """
                #{t("mailbox expunge ko")} #{error.message or error}
            """

        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, ->
            @alertError t('account removed')

        handle ActionTypes.CLEAR_TOASTS, ->
            _tasks = Immutable.OrderedMap()

        handle ActionTypes.RECEIVE_TASK_UPDATE, (task) =>
            _showNotification task

        handle ActionTypes.RECEIVE_TASK_DELETE, (taskid) ->
            _removeNotification taskid

        handle ActionTypes.MESSAGE_SEND_FAILURE, ({error, action}) ->
            if ActionTypes.MESSAGE_SEND_REQUEST is action
                msgKo = t "message action sent ko"
            else
                msgKo = t "message action draft ko"
            @alertError "#{msgKo} #{error}"

        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, ref, updated}) ->
            _showNotification
                message: _makeMessage target, ref, 'delete ok'
                actions: [_makeUndoAction ref]
                autoclose: true

        handle ActionTypes.MESSAGE_TRASH_FAILURE, ({target, ref, error}) ->
            _showNotification
                message: _makeMessage target, ref, 'delete ko', error
                errors: [error]
                autoclose: true

        handle ActionTypes.MESSAGE_MOVE_SUCCESS, ({target, ref, updated}) ->
            unless target.silent
                _showNotification
                    message: _makeMessage target, ref, 'move ok'
                    actions: [_makeUndoAction ref]
                    autoclose: true

        handle ActionTypes.MESSAGE_MOVE_FAILURE, ({target, ref, error}) ->
            _showNotification
                message: _makeMessage target, ref, 'move ko', error
                errors: [error]
                autoclose: true

        # dont display a notification for MESSAGE_FLAG_SUCCESS
        handle ActionTypes.MESSAGE_FLAGS_FAILURE, ({target, ref, error}) ->
            _showNotification
                message: _makeMessage target, ref, 'flag ko', error
                errors: [error]
                autoclose: true

        # dont display a notification for MESSAGE_RECOVER_SUCCESS
        handle ActionTypes.MESSAGE_RECOVER_FAILURE, ({target, ref, error}) ->
            _showNotification
                message: 'lost server connection'
                errors: [error]
                autoclose: true

        handle ActionTypes.MESSAGE_FETCH_FAILURE, ({error}) ->
            _showNotification
                message: 'message fetch failure'
                errors: [error]
                autoclose: true

        handle ActionTypes.ADD_ACCOUNT_FAILURE, ({error}) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]
            _showNotification
               message: RouterStore.getAlertErrorMessage()
               errors: RouterStore.getRawErrors()
               autoclose: true

        handle ActionTypes.ADD_ACCOUNT_SUCCESS, ({areMailboxesConfigured}) ->
            if areMailboxesConfigured
                key = "account creation ok"
            else
                key = "account creation ok configuration needed"

            _showNotification
                message: t key
                autoclose: true

        handle ActionTypes.EDIT_ACCOUNT_FAILURE, ({error}) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]
            _showNotification
               message: RouterStore.getAlertErrorMessage()
               errors: RouterStore.getRawErrors()
               autoclose: true

        handle ActionTypes.EDIT_ACCOUNT_SUCCESS, ->
            _showNotification
                message: t 'account updated'
                autoclose: true

        handle ActionTypes.CHECK_ACCOUNT_FAILURE, ({error}) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]
            _showNotification
               message: RouterStore.getAlertErrorMessage()
               errors: RouterStore.getRawErrors()
               autoclose: true

        handle ActionTypes.CHECK_ACCOUNT_SUCCESS, ->
            _showNotification
                message: t 'account checked'
                autoclose: true

        handle ActionTypes.REFRESH_FAILURE, ({error}) ->
            AppDispatcher.waitFor [AccountStore.dispatchToken]

            if error.name is 'AccountConfigError'
                message = t "config error #{error.field}"
            else
                message = error.message or error.name or error

            _showNotification
                message: message
                errors: [error]
                autoclose: true

module.exports = (_self = new NotificationStore())
