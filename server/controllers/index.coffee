async = require 'async'
Mailbox = require '../models/Mailbox'

#CozyInstance = require '../models/cozy_instance'

module.exports.main = (req, res, next) ->
    async.parallel [
        #(cb) -> CozyInstance.getLocale cb
        (cb) -> Mailbox.getAll cb

    ], (err, results) ->

        if err then next err
        else
            [mailboxes] = results
            res.render 'index.jade', imports: """
                window.mailboxes = #{JSON.stringify mailboxes};
            """