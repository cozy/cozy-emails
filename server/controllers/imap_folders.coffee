ImapFolder = require '../models/imap_folder'

module.exports.listByMailbox = (req, res, next) ->

    ImapFolder.getByMailbox req.mailbox.id, (err, emails) ->
        if err? then next err
        else
            res.send 200, emails

module.exports.fetch = (req, res, next) ->

    ImapFolder.find req.params.id, (err, imapFolder) ->
        if err? then next err
        else if not imapFolder?
            err = new Error 'Not found'
            err.status = 404
            next err
        else
            req.imapFolder = imapFolder
            next()