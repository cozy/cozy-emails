async = require 'async'
Account = require '../models/account'
cozydb = require 'cozydb'

module.exports.main = (req, res, next) ->
    async.series [
        (cb) -> cozydb.api.getCozyLocale cb
        (cb) -> Account.request 'all', cb
    ], (err, results) ->

        if err?
            # for now we handle error case loosely
            console.log err
            res.render 'test.jade', imports: """
                console.log("#{err}")
                window.locale = "en";
                window.accounts = {};
            """
        else
            [locale, accounts] = results
            res.render 'test.jade', imports: """
                window.locale   = "#{locale}";
                window.accounts = #{JSON.stringify accounts};
            """
