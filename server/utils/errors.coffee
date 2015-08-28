module.exports = utils = {}
americano = require 'americano'

# Something is wrong with the account's config
# field give more information about what's wrong
utils.AccountConfigError = class AccountConfigError extends Error
    constructor: (field, originalErr) ->
        @name = 'AccountConfigError'
        @field = field
        @message = "on field '#{field}'"
        @stack = ''
        @original = originalErr
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

utils.TimeoutError = class TimeoutError extends Error
    constructor: (msg) ->
        @name = 'Timeout'
        @status = 400
        @message = 'Timeout: ' + msg
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


utils.RefreshError = class RefreshError extends Error
    constructor: (payload) ->
        @name = 'Refresh'
        @status = 500
        @message = 'Error occured during refresh'
        @payload = payload
        Error.captureStackTrace this, arguments.callee
        return this

utils.PasswordEncryptedError = class PasswordEncryptedError extends Error
    constructor: (account) ->
        @name = 'PasswordEncryptedError'
        @status = 500
        @message = """
            Password is still encrypted in DS for account #{account.label}"""
        @account = account
        Error.captureStackTrace this, arguments.callee
        return this

# Error predicates
utils.isFolderForbidden = (err) ->
    /Folder name (.*) is not allowed./.test err.message

utils.isFolderDuplicate = (err) ->
    /Duplicate folder name/.test err.message

utils.isFolderUndeletable = (err) ->
    /Internal folder cannot be deleted/.test err.message


log = require('../utils/logging')(prefix: 'errorhandler')
baseHandler = americano.errorHandler()
utils.errorHandler = (err, req, res, next) ->
    log.debug "ERROR HANDLER CALLED", err

    if err instanceof utils.AccountConfigError or
       err.textCode is 'AUTHENTICATIONFAILED'
        res.status(400).send
            name: err.name
            field: err.field
            stack: err.stack
            error: true


    else if err.message is 'Request aborted'
        log.warn "Request aborted"


    else if err instanceof utils.RefreshError
        res.status(err.status).send
            name: err.name
            message: err.message
            payload: err.payload


    # pass it down the line to errorhandler module
    else
        log.error "error handler called with", err.stack
        baseHandler err, req, res
