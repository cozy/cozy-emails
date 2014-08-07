Email = require '../models/Email'

module.exports.listByMailbox = (req, res, next) ->

    Email.getByMailbox req.mailbox.id, (err, emails) ->
        if err? then next err
        else
            res.send 200, emails

module.exports.fetch = (req, res, next) ->

    Email.find req.params.id, (err, email) ->
        if err? then next err
        else if not email?
            err = new Error 'Not found'
            err.status = 404
            next err
        else
            req.email = email
            next()

module.exports.get = (req, res, next) ->
    res.send 200, req.email