Scheduler    = require '../processes/_scheduler'
Account      = require '../models/account'
Contact      = require '../models/contact'
Settings     = require '../models/settings'
CONSTANTS    = require '../utils/constants'
async        = require 'async'
cozydb       = require 'cozydb'
log          = require('../utils/logging')(prefix: 'controllers:index')
ramStore     = require '../models/store_account_and_boxes'


# render the application index
# with all necessary imports
module.exports.main = (req, res, next) ->

    if Scheduler.applicationStartupRunning()
        if req.hasWaitedForStart
            res.render 'reindexing'
        else
            req.hasWaitedForStart = true
            tryAgain = -> module.exports.main req, res, next
             # if the app can start under 2s, we wont show the need reindexing
            setTimeout tryAgain, 2000
        return null

    async.series [
        (cb) -> Settings.getDefault cb
        (cb) -> cozydb.api.getCozyLocale cb
        (cb) -> cb null, ramStore.clientList()
        (cb) -> Contact.list cb
    ], (err, results) ->

        refreshes = Scheduler.clientSummary()

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

            # Prepare page pre-loaded data
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
    Scheduler.startAllRefresh (err) ->
        log.error "REFRESHING ACCOUNT FAILED", err if err
        return next err if err
        res.send refresh: 'done'


# get a list of all background operations on the server
module.exports.refreshes = (req, res, next) ->
    res.send Scheduler.clientSummary()
