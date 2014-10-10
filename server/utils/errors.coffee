module.exports = utils = {}


utils.AccountConfigError = class AccountConfigError extends Error
    constructor: (field) ->
        @name = 'AccountConfigError'
        @field = field
        @message = "on field '#{field}'"
        @stack = ''
        # WE DONT NEED STACK FOR THIS ERROR
        # Error.captureStackTrace this, arguments.callee
        return this

utils.WrongConfigError = class WrongConfigError extends Error
    constructor: (field) ->
        @name = 'WrongConfigError'
        @field = field
        @message = "Wrong Imap config on field #{field}"
        Error.captureStackTrace this, arguments.callee
        return this

utils.UIDValidityChanged = class UIDValidityChanged extends Error
    constructor: (uidvalidity) ->
        @name = UIDValidityChanged
        @newUidvalidity = uidvalidity
        @message = "UID Validty has changed"
        Error.captureStackTrace this, arguments.callee
        return this

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