CozyInstance = require '../models/cozy_instance'
Account = require '../models/account'
Promise = require 'bluebird'

fixtures = require 'cozy-fixtures'

module.exports.main = (req, res, next) ->
    Promise.all [
        CozyInstance.getLocalePromised()
            .catch (err) -> 'en'

        Account.getAllPromised()
            .map (account) -> account.includeMailboxes()
    ]
    .spread (locale, accounts) ->
        """
            window.locale = "#{locale}";
            window.accounts = #{JSON.stringify accounts};
        """

    # for now we handle error case loosely
    .catch (err) ->
        console.log err.stack

        """
            console.log("#{err}");
            window.locale = "en"
            window.accounts = []
        """

    .then (imports) ->
        res.render 'index.jade', {imports}


module.exports.loadFixtures = (req, res, next) ->
    fixtures.load silent: true, callback: (err) ->
        if err? then next err
        else
            res.send 200, message: 'LOAD FIXTURES SUCCESS'
