levels = ['debug', 'log', 'info', 'warn', 'error']
console = window.console or {}

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

wrapLog = (level) ->
    consolefn = console[level]
    (args...) ->

        if level in ['warn', 'error']
            _sendReport level, args

        # display in console if not in production mode
        consolefn.call console, args...


module.exports.initialize = ->
    console[level] = wrapLog level for level in levels
    window.console ?= console

    window.onerror = (args...) ->
        error = args[args.length - 1]
        _sendReport.call null, 'error', error
        console.error error
        # prevent native runtime error
        return __DEV__

module.exports.report = _sendReport
