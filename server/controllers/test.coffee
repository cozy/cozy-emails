async = require 'async'
Account = require '../models/account'

CozyInstance = require '../models/cozy_instance'

fixtures = require 'cozy-fixtures'

module.exports.main = (req, res, next) ->
    async.parallel [
        (cb) -> CozyInstance.getLocale cb
        (cb) -> Account.getAll cb
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
            accounts = accounts.map Account.clientVersion
            res.render 'test.jade', imports: """
                window.locale   = "#{locale}";
                window.accounts = #{JSON.stringify accounts};
            """
