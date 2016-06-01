ioclient = require 'socket.io-client'

AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes} = require '../constants/app_constants'

_socket = undefined
_lastError = undefined



_setServerScope = (params={}) ->
    _socket?.emit 'change_scope', params


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
        console.info "
            Response: #{timing.responseEnd - timing.navigationStart}ms
            Onload: #{timing.loadEventStart - timing.navigationStart}ms
            Page loaded: #{now}ms
        "


_initRealtime = ->
    _socket = ioclient.connect window.location.origin,
        path: "#{window.location.pathname}socket.io"
        reconnectionDelayMax: 60000
        reconectionDelay: 2000
        reconnectionAttempts: 3

    _socket.on 'refreshes.status',
        _dispatchAs ActionTypes.RECEIVE_REFRESH_STATUS

    _socket.on 'refresh.create',
        _dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
    _socket.on 'refresh.update',
        _dispatchAs ActionTypes.RECEIVE_REFRESH_UPDATE
    _socket.on 'refresh.delete',
        _dispatchAs ActionTypes.RECEIVE_REFRESH_DELETE

    _socket.on 'message.create',
        _dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
    _socket.on 'message.update',
        _dispatchAs ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
    _socket.on 'message.delete',
        _dispatchAs ActionTypes.RECEIVE_MESSAGE_DELETE

    _socket.on 'account.create',
        _dispatchAs ActionTypes.RECEIVE_ACCOUNT_CREATE
    _socket.on 'account.update',
        _dispatchAs ActionTypes.RECEIVE_ACCOUNT_UPDATE

    _socket.on 'mailbox.create',
        _dispatchAs ActionTypes.RECEIVE_MAILBOX_CREATE
    _socket.on 'mailbox.update',
        _dispatchAs ActionTypes.RECEIVE_MAILBOX_UPDATE
    _socket.on 'refresh.notify',
        _dispatchAs ActionTypes.RECEIVE_REFRESH_NOTIF


_initReporting = ->
    return unless __DEV__
    console = window.console or {}
    levels = ['debug', 'log', 'info', 'warn', 'error']

    wrapLog = (level) ->
        consolefn = console[level]
        (args...) ->

            if level in ['warn', 'error']
                _sendReport level, args

            # display in console if not in production mode
            consolefn.call console, args...

    console[level] = wrapLog level for level in levels

    window.onerror = (args...) ->
        error = args[args.length - 1]
        _sendReport.call null, 'error', error
        # prevent native runtime error
        return __DEV__


_initDesktopNotifications = ->
    if window.settings?.desktopNotifications and window.Notification
        Notification.requestPermission (status) ->
            # This allows to use Notification.permission
            # with Chrome/Safari
            if Notification.permission isnt status
                Notification.permission = status


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
    xhr.open 'POST', 'activity', true
    xhr.setRequestHeader "Content-Type", "application/json;charset=UTF-8"
    xhr.send JSON.stringify {data}

    _lastError = err


_dispatchAs = (type) -> (value) ->
    AppDispatcher.dispatch {type, value}


module.exports.setServerScope = _setServerScope


module.exports.initialize = ->
    try
        # Initialize system
        _initReporting()
        _initPerformances()

        # Initialize discussions
        _initRealtime()
        _initDesktopNotifications()

        _socket?.on 'connect', -> _setServerScope()
        _socket?.on 'reconnect', -> _setServerScope()

    catch err
        _sendReport 'error', err
