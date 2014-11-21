
async.timeoutProtect = (ms, callback) ->

    # create out of callback, so we have a stack
    error = new TimeoutError()
    first = false

    timeout = setTimeout ->
        if first then callback error
        first = false
    , ms

    return newCallback = ->
        clearTimeout timeout
        if first then callback.apply null, arguments
        first = false


async.delay = (ms, fn) ->
    setTimeout fn, ms