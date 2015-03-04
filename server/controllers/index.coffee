ImapReporter = require '../imap/reporter'
Account      = require '../models/account'
Contact      = require '../models/contact'
Settings     = require '../models/settings'
CONSTANTS    = require '../utils/constants'
async        = require 'async'
cozydb       = require 'cozydb'
log          = require('../utils/logging')(prefix: 'controllers:index')


module.exports.main = (req, res, next) ->

    async.series [
        (cb) -> Settings.getDefault cb
        (cb) -> cozydb.api.getCozyLocale cb
        (cb) -> Account.clientList cb
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
                res.send message: 'LOAD FIXTURES SUCCESS'

module.exports.refresh = (req, res, next) ->
    if req.query?.all
        limitByBox    = null
        onlyFavorites = false
    else
        limitByBox    = CONSTANTS.LIMIT_BY_BOX
        onlyFavorites = true

    Account.refreshAllAccounts limitByBox, onlyFavorites, (err) ->
        log.error "REFRESHING ACCOUNT FAILED", err if err
        return next err if err
        res.send refresh: 'done'

module.exports.refreshes = (req, res, next) ->
    res.send ImapReporter.summary()
