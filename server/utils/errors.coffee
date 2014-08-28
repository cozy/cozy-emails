module.exports = utils = {}

utils.HttpError = (status, msg) ->
    Error.call this
    Error.captureStackTrace this, arguments.callee
    this.status = status
    this.message = msg
    this.name = 'HttpError'