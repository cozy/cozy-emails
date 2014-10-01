
COLORS = [
    '\x1B[32mDEBUG\x1B[39m'
    '\x1B[34mINFO\x1B[39m'
    '\x1B[33mWARN\x1B[39m'
    '\x1B[31mERROR\x1B[39m'
]

LOG_LEVEL = if process.env.DEBUG_LEVEL? then parseInt process.env.DEBUG_LEVEL
else if process.env.NODE_ENV is 'test' then 3
else if process.env.NODE_ENV is 'production' then 1
else 0


module.exports = (options) ->

    prefix = if typeof options is 'string' then options
    else options.prefix

    logger = (level) -> () ->
        return null if level < LOG_LEVEL
        args = new Array arguments.length + 2
        args[0] = COLORS[level]
        args[1] = prefix
        for arg, i in arguments
            args[i+2] = arg
        
        console.log.apply console, args

    return api = 
        debug: logger 0
        info: logger 1
        warn: logger 2
        error: logger 3
