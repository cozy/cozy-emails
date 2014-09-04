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
            res.render 'index.jade', imports: """
                console.log("#{err}")
                window.locale = "en";
                window.accounts = {};
            """
        else
            [locale, accounts] = results
            accounts = accounts.map Account.clientVersion
            res.render 'index.jade', imports: """
                window.locale = "#{locale}";
                window.accounts = #{JSON.stringify accounts};
            """

module.exports.loadFixtures = (req, res, next) ->
    fixtures.load silent: true, callback: (err) ->
        if err? then next err
        else
            res.send 200, message: 'LOAD FIXTURES SUCCESS'
