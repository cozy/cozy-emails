util = require 'util'

COLORS = [
    '\x1B[32mDBUG\x1B[39m'
    '\x1B[34mINFO\x1B[39m'
    '\x1B[33mWARN\x1B[39m'
    '\x1B[31mEROR\x1B[39m'
]

LOG_LEVEL = if process.env.DEBUG_LEVEL? then parseInt process.env.DEBUG_LEVEL
else if process.env.NODE_ENV is 'test' then 3
else if process.env.NODE_ENV is 'production' then 1
else 0

lastLogs = new Array(15)
index = -1

addToLastLogs = ->
    index = (index + 1) % 15
    lastLogs[index] = util.format.apply this, arguments


module.exports = (options) ->

    prefix = if typeof options is 'string' then options
    else options.prefix

    logger = (level) -> ->


        args = new Array arguments.length + 2
        args[0] = COLORS[level]
        args[1] = prefix
        for arg, i in arguments
            args[i+2] = arg

        addToLastLogs args

        return null if level < LOG_LEVEL or prefix is 'imap:raw'

        console.log.apply console, args

    return api =
        debug: logger 0
        info: logger 1
        warn: logger 2
        error: logger 3

module.exports.getLasts = ->
    return lastLogs.join("\n")
