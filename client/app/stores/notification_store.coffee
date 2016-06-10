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


    ###
        Public API
    ###
    getToasts: ->
        return _tasks


    ###
        Private API
    ###

    _alert = (message) ->
        _notify message,
            level: AlertLevel.INFO
            autoclose: true


    _alertSuccess = (message) ->
        _notify message,
            level: AlertLevel.SUCCESS
            autoclose: true


    _alertWarning = (message) ->
        _notify message,
            level: AlertLevel.WARNING
            autoclose: true


    _alertError = (message) ->
        _notify message,
            level: AlertLevel.ERROR
            autoclose: true


    _notify = (message, options) ->
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


    _removeNotification = (id) ->
        _tasks = _tasks.remove id


    _showNotification = (options) ->
        id = options.id or +Date.now()
        options.finished ?= true
        _tasks = _tasks.set id, Immutable.Map options
        if options.autoclose
            setTimeout _removeNotification.bind(@, id), 5000


    _makeMessage = (target, actionAndOK, errMsg)->
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


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.SETTINGS_UPDATE_FAILURE, ({error}) ->
            _alertError t('settings save error') + error


        handle ActionTypes.MAILBOX_CREATE_SUCCESS, ->
            _alertSuccess t("mailbox create ok")


        handle ActionTypes.MAILBOX_CREATE_FAILURE, ->
            message = "#{t("mailbox create ko")} #{error.message or error}"
            _alertError message


        handle ActionTypes.MAILBOX_UPDATE_SUCCESS, ->
            _alertSuccess t("mailbox update ok")


        handle ActionTypes.MAILBOX_UPDATE_FAILURE, ->
            message = "#{t("mailbox update ko")} #{error.message or error}"
            _alertError message


        handle ActionTypes.MAILBOX_EXPUNGE_SUCCESS, ->
            _alert t("mailbox expunge ok"), autoclose: true


        handle ActionTypes.MAILBOX_EXPUNGE_FAILURE, ({error, mailboxID, accountID}) ->
            _alertError """
                #{t("mailbox expunge ko")} #{error.message or error}
            """


        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, ->
            _alertError t('account removed')


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
            _alertError "#{msgKo} #{error}"


        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target}) ->
            _showNotification
                message: _makeMessage target, 'delete ok'
                autoclose: true

        handle ActionTypes.MESSAGE_TRASH_FAILURE, ({target, error}) ->
            _showNotification
                message: _makeMessage target, 'delete ko', error
                errors: [error]
                autoclose: true

        handle ActionTypes.MESSAGE_MOVE_SUCCESS, ({target}) ->
            unless target.silent
                _showNotification
                    message: _makeMessage target, 'move ok'
                    autoclose: true

        handle ActionTypes.MESSAGE_MOVE_FAILURE, ({target, error}) ->
            _showNotification
                message: _makeMessage target, 'move ko', error
                errors: [error]
                autoclose: true


        # dont display a notification for MESSAGE_FLAG_SUCCESS
        handle ActionTypes.MESSAGE_FLAGS_FAILURE, ({target, error}) ->
            _showNotification
                message: _makeMessage target, 'flag ko', error
                errors: [error]
                autoclose: true


        handle ActionTypes.MESSAGE_FETCH_FAILURE, ({error}) ->
            _showNotification
                message: 'message fetch failure'
                errors: [error]
                autoclose: true


        handle ActionTypes.EDIT_ACCOUNT_SUCCESS, ->
            _showNotification
                message: t 'account updated'
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


        handle ActionTypes.SEARCH_CONTACT_FAILURE, ({error}) ->
            _showNotification
                message: message
                errors: [error]
                autoclose: true


        handle ActionTypes.CREATE_CONTACT_SUCCESS, ({error, result}) ->
            _showNotification
                message: t 'contact create success',
                    contact: result?.name or result?.address
                autoclose: true


        handle ActionTypes.CREATE_CONTACT_FAILURE, ({error}) ->
            _showNotification
                message: t 'contact create error', {error}
                errors: [error]
                autoclose: true


        handle ActionTypes.RECEIVE_REFRESH_NOTIF, ({message}) ->
            _showNotification
                message: "#{t 'notif new title'} #{message}"
                autoclose: true


module.exports = new NotificationStore()
