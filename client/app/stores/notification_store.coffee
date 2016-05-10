ioclient = require('socket.io-client')

_         = require 'underscore'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'
AccountStore = require '../stores/account_store'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes, AlertLevel} = require '../constants/app_constants'

LOG_URL = 'activity'

class NotificationStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _uniqID = 0
    _tasks = Immutable.OrderedMap()

    _scope  = {}
    _socket = undefined

    _lastError = undefined


    ###
        Public API
    ###
    getToasts: ->
        return _tasks


    ###
        Private API
    ###

    _dispatchAs = (type) -> (value) ->
        AppDispatcher.dispatch {type, value}


    __setServerScope = (params={}) ->
        _scope = params
        _socket.emit 'change_scope', _scope if _socket


    _initRealtime = ->
        _socket = ioclient.connect window.location.origin,
            path: "#{window.location.pathname}socket.io"
            reconnectionDelayMax: 60000
            reconectionDelay: 2000
            reconnectionAttempts: 3

        _socket.on 'connect', -> _setServerScope()
        _socket.on 'reconnect', -> _setServerScope()

        _socket.on 'refresh.status', _dispatchAs ActionTypes.RECEIVE_REFRESH_STATUS
        _socket.on 'refresh.create', _dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
        _socket.on 'refresh.update', _dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
        _socket.on 'refresh.delete', _dispatchAs ActionTypes.RECEIVE_REFRESH_DELETE

        _socket.on 'message.create',
            _dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
        _socket.on 'message.update',
            _dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
        _socket.on 'message.delete',
            _dispatchAs ActionTypes.RECEIVE_MESSAGE_DELETE
        _socket.on 'mailbox.update',
            _dispatchAs ActionTypes.RECEIVE_MAILBOX_UPDATE
        _socket.on 'refresh.notify',
            _dispatchAs ActionTypes.RECEIVE_REFRESH_NOTIF


    _updateScope = (args) ->
        {mailboxID, before} = args
        setServerScope {mailboxID, before}


    _initReporting = ->
        console = window.console or {}

        levels = ['debug', 'log', 'info', 'warn', 'error']

        wrapLog = (level) ->
            consolefn = console[level]

            (args...) ->
                if __DEV__ or level in ['warn', 'error']
                    _sendReport level, JSON.stringify args
                # display in console if not in production mode
                consolefn.apply console, args if __DEV__

        console[level] = wrapLog level for level in levels

        window.onerror = (args...) ->
            error = args[args.length - 1]
            _sendReport.call null, 'error', error
            # prevent native runtime error
            return __DEV__

    _sendReport = (level, err) ->
        return if err is _lastError

        data =
            type:  level
            href:  window.location.href

        if err instanceof Error
            data.line  = err.lineNumber
            data.col   = err.columnNumber
            data.url   = err.fileName
            data.error =
                msg:   err.message
                name:  err.name
                stack: err.stack
        else if level is 'error'
            data.error = msg: err
        else
            data.msg = err

        xhr = new XMLHttpRequest()
        xhr.open 'POST', LOG_URL, true
        xhr.setRequestHeader "Content-Type", "application/json;charset=UTF-8"
        xhr.send JSON.stringify {data}

        _lastError = err


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

    _makeUndoAction = (ref) ->
        label: t 'action undo'
        onClick: -> getMessageActionCreator().undo ref


    _initialize = ->
        try
            # Initialize system
            _initReporting()
            _initPerformances()

            # Initialize discussions
            _initRealtime()
            _initDesktopNotifications()

        catch err
            _sendReport 'error', err


    _initDesktopNotifications = ->
        if window.settings.desktopNotifications and window.Notification
            Notification.requestPermission (status) ->
                # This allows to use Notification.permission
                # with Chrome/Safari
                if Notification.permission isnt status
                    Notification.permission = status


    _initPerformances = ->
        return unless __DEV__
        referencePoint = 0
        window.start = ->
            referencePoint = performance.now() if performance?.now?
            Perf.start()
        window.stop = ->
            console.log performance.now() - referencePoint if performance?.now?
            Perf.stop()
        window.printWasted = ->
            stop()
            Perf.printWasted()
        window.printInclusive = ->
            stop()
            Perf.printInclusive()
        window.printExclusive = ->
            stop()
            Perf.printExclusive()

        # starts perfs logging
        timing = window.performance?.timing
        now = Math.ceil window.performance?.now()
        if timing?
            message = "
                Response: #{timing.responseEnd - timing.navigationStart}ms
                Onload: #{timing.loadEventStart - timing.navigationStart}ms
                Page loaded: #{now}ms
            "
            _alert message


    _initialize()


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

        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, ref, updated}) ->
            _showNotification
                message: _makeMessage target, 'delete ok'
                actions: [_makeUndoAction ref]
                autoclose: true

        handle ActionTypes.MESSAGE_TRASH_FAILURE, ({target, ref, error}) ->
            _showNotification
                message: _makeMessage target, 'delete ko', error
                errors: [error]
                autoclose: true

        handle ActionTypes.MESSAGE_MOVE_SUCCESS, ({target, ref, updated}) ->
            unless target.silent
                _showNotification
                    message: _makeMessage target, 'move ok'
                    actions: [_makeUndoAction ref]
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


        handle ActionTypes.MESSAGE_FETCH_SUCCESS, (payload) ->
            {result, timestamp} = payload

            # Update Realtime
            lastMessage = result?.messages?.last()
            mailboxID = lastMessage?.get 'mailboxID'
            before = lastMessage?.get('date') or timestamp
            _updateScope {mailboxID, before}

            @emit 'change'


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
