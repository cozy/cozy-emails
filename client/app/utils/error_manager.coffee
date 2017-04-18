LOG_URL = 'activity'
lastError = undefined

module.exports.sendReport = sendReport = (level, err) ->
    return if err is lastError

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

    lastError = err


module.exports.initReporting = ->
    console = window.console or {}

    levels = ['debug', 'log', 'info', 'warn', 'error']

    wrapLog = (level) ->
        consolefn = console[level]

        (args...) ->
            if __DEV__ or level in ['warn', 'error']
                sendReport level, JSON.stringify args
            # display in console if not in production mode
            consolefn.apply console, args if __DEV__

    console[level] = wrapLog level for level in levels

    window.onerror = (args...) ->
        error = args[args.length - 1]
        sendReport.call null, 'error', error
        # prevent native runtime error
        return __DEV__
