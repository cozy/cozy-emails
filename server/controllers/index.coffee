async = require 'async'
Mailbox = require '../models/mailbox'

CozyInstance = require '../models/cozy_instance'

fixtures = require 'cozy-fixtures'

module.exports.main = (req, res, next) ->
    async.parallel [
        (cb) -> CozyInstance.getLocale cb
        (cb) -> Mailbox.getAll cb

    ], (err, results) ->

        if err?
            # for now we handle error case loosely
            res.render 'index.jade', imports: ""
        else
            [locale, accounts] = results
            res.render 'index.jade', imports: """
                window.locale = "#{locale}";
                window.accounts = #{JSON.stringify accounts};
            """

module.exports.loadFixtures = (req, res, next) ->
    fixtures.load silent: true, callback: (err) ->
        if err? then next err
        else
            res.send 200, message: 'LOAD FIXTURES SUCCESS'