util = require 'util'

COLORS = [
    '\x1B[32mDBUG\x1B[39m'
    '\x1B[34mINFO\x1B[39m'
    '\x1B[33mWARN\x1B[39m'
    '\x1B[31mEROR\x1B[39m'
]

# LOG_LEVEL = if process.env.DEBUG_LEVEL? then parseInt process.env.DEBUG_LEVEL
# else if process.env.NODE_ENV is 'test' then 3
# else if process.env.NODE_ENV is 'production' then 1
# else 0

LOG_LEVEL = 0

lastLogs = new Array(15)
lastDate = +new Date()
index = -1
MAX_INDEX = 15

addToLastLogs = ->
    index = (index + 1) % MAX_INDEX
    lastLogs[index] = util.format.apply this, arguments

pad = (nb) ->
    ((nb + 10000) + "").substring 1

module.exports = (options) ->

    prefix = if typeof options is 'string' then options
    else options.prefix

    logger = (level) -> ->

        newDate = +new Date()
        delta = newDate - lastDate
        lastDate = newDate

        args = new Array arguments.length + 3
        args[0] = COLORS[level]
        args[1] = "+" + ((delta + 10000) + "").substring 1
        args[2] = prefix
        for arg, i in arguments
            args[i+3] = arg


        addToLastLogs.apply null, args
        return null if level < LOG_LEVEL

        console.log.apply console, args

    return api =
        debug: logger 0
        info: logger 1
        warn: logger 2
        error: logger 3

module.exports.getLasts = ->
    return lastLogs[index+1..MAX_INDEX].join("\n") + "\n" +
           lastLogs[0..index].join("\n")
