CozyInstance = require '../models/cozy_instance'
ImapReporter = require '../imap/reporter'
Account  = require '../models/account'
Contact  = require '../models/contact'
Settings = require '../models/settings'
async = require 'async'
log = require('../utils/logging')(prefix: 'controllers:index')


module.exports.main = (req, res, next) ->

    async.series [
        Settings.get
        CozyInstance.getLocale
        Account.clientList
        (callback) ->
            Contact.requestWithPictures 'all', {}, callback
    ], (err, results) ->

        refreshes = ImapReporter.summary()

        if err
            log.error err.stack

            imports = """
                console.log("#{err}");
                window.locale = "en"
                window.refreshes = []
                window.accounts  = []
                window.contacts  = []
            """
        else
            [settings, locale, accounts, contacts] = results
            imports = """
                window.settings  = #{JSON.stringify settings}
                window.refreshes = #{JSON.stringify refreshes};
                window.locale    = "#{locale}";
                window.accounts  = #{JSON.stringify accounts};
                window.contacts  = #{JSON.stringify contacts};
            """

        res.render 'index.jade', {imports}


module.exports.loadFixtures = (req, res, next) ->
    try fixtures = require 'cozy-fixtures'
    catch e then return next new Error 'only in tests'

    fixtures.load
        silent: true,
        callback: (err) ->
            if err
                return next err
            else
                res.send 200, message: 'LOAD FIXTURES SUCCESS'

module.exports.refresh = (req, res, next) ->
    if req.query?.all
        limit = undefined
        onlyFavorites = false
    else
        limit = 1000
        onlyFavorites = true

    Account.refreshAllAccounts limit, onlyFavorites, (err) ->
        return next err if err
        res.send 200, refresh: 'done'

module.exports.refreshes = (req, res, next) ->
    res.send 200, ImapReporter.summary()
