Message = require '../models/message'
{HttpError} = require '../utils/errors'

module.exports.listByMailboxId = (req, res, next) ->

    # @TODO : add query parameters for sort & pagination

    Message.getByMailboxAndDatePromised(req.params.mailboxID)
        .then (messages) -> res.send 200, messages
        .catch next

module.exports.fetch = (req, res, next) ->
    Message.findPromised(req.params.messageID)
        .then (message) ->
            if message then req.message = message
            else throw new HttpError 404, 'Not Found'
        .nodeify next

module.exports.details = (req, res, next) ->

    # @TODO : fetch message's status
    # @TODO : fetch whole conversation ?

    res.send 200, req.message

module.exports.updateFlags = (req, res, next) ->

    # @TODO : fetch message's status
    # @TODO : make sure we only update flags
    # @TODO : do the change in IMAP before ?

    next new Error 'not implemented'