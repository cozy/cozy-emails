async = require 'async'
Mailbox = require '../models/mailbox'

CozyInstance = require '../models/cozy_instance'

module.exports.main = (req, res, next) ->
    async.parallel [
        (cb) -> CozyInstance.getLocale cb
        (cb) -> Mailbox.getAll cb

    ], (err, results) ->

        if err?
            # for now we handle error case loosely
            res.render 'index.jade', imports: ""
        else
            [locale, mailboxes] = results
            res.render 'index.jade', imports: """
                window.locale = "#{locale}";
                window.mailboxes = #{JSON.stringify mailboxes};
            """
