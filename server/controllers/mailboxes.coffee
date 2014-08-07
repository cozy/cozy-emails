async = require 'async'

Mailbox = require '../models/Mailbox'
Email = require '../models/Email'

module.exports.create = (req, res, next) ->

    Mailbox.create req.body, (err, mailbox) ->
        if err? then next err
        else
            res.send 201, mailbox

module.exports.list = (req, res, next) ->

    Mailbox.getAll (err, mailboxes) ->
        if err? then next err
        else
            res.send 200, mailboxes

module.exports.fetch = (req, res, next) ->

    Mailbox.find req.params.id, (err, mailbox) ->
        if err? then next err
        else if not mailbox?
            err = new Error 'Not found'
            err.status = 404
            next err
        else
            req.mailbox = mailbox
            next()

module.exports.edit = (req, res, next) ->

    req.mailbox.updateAttributes req.body, (err) ->
        if err? then next nerr
        else res.send 200, req.mailbox

module.exports.remove = (req, res, next) ->

    async.series [
        (cb) -> Email.destroyByMailbox req.mailbox.id, cb
        (cb) -> req.mailbox.destroy cb
    ], (err) ->
        if err? then next err
        else res.send 204
