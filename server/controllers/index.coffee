ImapReporter = require '../imap/reporter'
Account      = require '../models/account'
Contact      = require '../models/contact'
Settings     = require '../models/settings'
CONSTANTS    = require '../utils/constants'
async        = require 'async'
cozydb       = require 'cozydb'
log          = require('../utils/logging')(prefix: 'controllers:index')

# render the application index
# with all necessary imports
module.exports.main = (req, res, next) ->

    progress = cozydb.getRequestsReindexingProgress()
    if progress < 1
        return res.render 'reindexing'

    async.series [
        (cb) -> Settings.getDefault cb
        (cb) -> cozydb.api.getCozyLocale cb
        (cb) -> Account.clientList cb
        (cb) -> Contact.list cb
    ], (err, results) ->

        refreshes = ImapReporter.summary()

        if err
            log.error "err on index", err.stack

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
                window.app_env   = "#{process.env.NODE_ENV}";
            """

        res.render 'index', {imports}

# trigger a refresh of all accounts
# query.all
module.exports.refresh = (req, res, next) ->

    # Experiment: the refresh button is now used to refresh browser's data
    # with server's data, not for an actual imap refresh.

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


# get a list of all background operations on the server
module.exports.refreshes = (req, res, next) ->
    res.send ImapReporter.summary()
