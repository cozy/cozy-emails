module.exports = utils = {}

utils.customError = (name) ->
    return class CustomError extends Error
        constructor: (@message) ->
            @name = name
            Error.captureStackTrace(this, name)

utils.WrongConfigError = class WrongConfigError extends Error
    constructor: (field) ->
        @name = 'WrongConfigError'
        @field = field
        @message = "Wrong Imap config on field #{field}"
        Error.captureStackTrace this, arguments.callee

utils.HttpError = (status, msg) ->
    if msg instanceof Error
        msg.status = status
        return msg

    else
        Error.call this
        Error.captureStackTrace this, arguments.callee
        this.status = status
        this.message = msg
        this.name = 'HttpError'