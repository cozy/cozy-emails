async = require 'async'
Message = require '../models/message'
{HttpError} = require '../utils/errors'
Client = require('request-json').JsonClient
jsonpatch = require 'fast-json-patch'

# The data system listens to localhost:9101
dataSystem = new Client 'http://localhost:9101/'

# In production we must authenticate the application
if process.env.NODE_ENV in ['production', 'test']
    user = process.env.NAME
    password = process.env.TOKEN
    dataSystem.setBasicAuth user, password

# list messages from a mailbox
# require numPage & numByPage params
module.exports.listByMailboxId = (req, res, next) ->

    # @TODO : add query parameters for sort & pagination
    options =
        numPage: req.params.numPage - 1
        numByPage: req.params.numByPage

    Message.getByMailboxAndDate(req.params.mailboxID, options)
    .then (messages) -> res.send 200, messages
    .catch next

# give the number of messages for a mailbox
# @TODO : number of unread message ?
module.exports.countByMailboxId = (req, res, next) ->
    Message.countByMailbox(req.params.mailboxID)
    .then (count) -> res.send 200, count
    .catch next

# get a message and attach it to req.message
module.exports.fetch = (req, res, next) ->
    Message.findPromised req.params.messageID
    .then (message) ->
        if message then req.message = message
        else throw new HttpError 404, 'Not Found'
    .nodeify next

# return a message's details
module.exports.details = (req, res, next) ->

    # @TODO : fetch message's status
    # @TODO : fetch whole conversation ?

    res.send 200, req.message

# patch e message
module.exports.patch = (req, res, next) ->

    jsonpatch.apply req.message, req.body

    # @TODO : save message into DS
    res.send 200, req.message

# send a message through the DS
module.exports.send = (req, res, next) ->
    console.log "Server: ", typeof req.body
    dataSystem.post 'mail/', req.body, (dsErr, dsRes, dsBody) ->
        if dsErr
            res.send 500, dsBody
        else
            res.send 200, dsBody

# search in the messages using the indexer
module.exports.search = (req, res, next) ->

    if not req.params.query?
        next new HttpError 400, '`query` body field is mandatory'
    else
        # we add one temporary because the search doesn't return the
        # number of results so we can't paginate properly
        numPageCheat = parseInt(req.params.numPage) * parseInt(req.params.numByPage) + 1
        Message.searchPromised
            query: req.params.query
            numPage: req.params.numPage
            numByPage: numPageCheat
        .then (messages) -> res.send messages
        .catch next

# Temporary routes for testing purpose
module.exports.index = (req, res, next) ->
    Message.request 'all', {}, (err, messages) ->
        if err? then next err
        else
            async.each messages, (message, callback) ->
                message.index ['subject', 'text'], callback
            , (err) ->
                if err? then next err
                else res.send 200, 'Indexation OK'

module.exports.del = (req, res, next) ->

    # @TODO : move message to trash

    res.send 200, ""

