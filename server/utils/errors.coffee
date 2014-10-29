module.exports = utils = {}

# Something is wrong with the account's config
# field give more information about what's wrong
utils.AccountConfigError = class AccountConfigError extends Error
    constructor: (field) ->
        @name = 'AccountConfigError'
        @field = field
        @message = "on field '#{field}'"
        @stack = ''
        # WE DONT NEED STACK FOR THIS ERROR
        # Error.captureStackTrace this, arguments.callee
        return this

# Utility exception to break of promises chain
utils.Break = class Break extends Error
    constructor: ->
        @name = 'Break'
        @stack = ''
        return this

# Attempted to do something the imap server doesn't like
# Possible codes :
#  - folder undeletable
#  - folder forbidden
#  - folder duplicate
utils.ImapImpossible = class ImapImpossible extends Error
    constructor: (code, originalErr) ->
        @name = 'ImapImpossible'
        @code = code
        @original = originalErr
        @message = originalErr.message
        Error.captureStackTrace this, arguments.callee
        return this

# the box UIDvalidity has changed
utils.UIDValidityChanged = class UIDValidityChanged extends Error
    constructor: (uidvalidity) ->
        @name = 'UIDValidityChanged'
        @newUidvalidity = uidvalidity
        @message = "UID Validty has changed"
        Error.captureStackTrace this, arguments.callee
        return this

utils.NotFound = class NotFound extends Error
    constructor: (msg) ->
        @name = 'NotFound'
        @status = 404
        @message = "Not Found: " + msg
        Error.captureStackTrace this, arguments.callee
        return this

utils.BadRequest = class BadRequest extends Error
    constructor: (msg) ->
        @name = 'BadRequest'
        @status = 400
        @message = 'Bad request : ' + msg
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