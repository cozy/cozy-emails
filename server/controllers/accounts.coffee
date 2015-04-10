_ = require 'lodash'
Account = require '../models/account'
{AccountConfigError} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'accounts:controller')
async = require 'async'
notifications = require '../utils/notifications'



# Middleware : fetch an account by id, add it to the request
module.exports.fetch = (req, res, next) ->
    id = req.params.accountID or
         req.body.accountID or
         req.mailbox.accountID or
         req.message.accountID

    Account.findSafe id, (err, found) ->
        return next err if err
        req.account = found
        next()

# Middleware : format res.account for client usage
module.exports.format = (req, res, next) ->
    log.debug "FORMATTING ACCOUNT"
    res.account.toClientObject (err, formated) ->
        log.debug "SENDING ACCOUNT"
        return next err if err
        res.send formated

# Middleware : format res.accounts for client usage
module.exports.formatList = (req, res, next) ->
    async.mapSeries res.accounts, (account, callback) ->
        account.toClientObject callback

    , (err, formateds) ->
        return next err if err
        res.send formateds

# create an account
# and lauch fetching of this account mails
module.exports.create = (req, res, next) ->
    # @TODO : validate req.body
    data = req.body
    Account.createIfValid data, (err, created) ->
        return next err if err
        res.account = created
        next()
        # in the background, start fetching mails
        res.account.imap_fetchMailsTwoSteps (err) ->
            log.error "FETCH MAIL FAILED", err.stack or err if err
            notifications.accountFirstImportComplete res.account

# check account parameters
module.exports.check = (req, res, next) ->
    tmpAccount = new Account req.body
    tmpAccount.testConnection (err) ->
        return next err if err
        res.send check: 'ok'

# fetch the list of all Accounts
# include the account mailbox tree
module.exports.list = (req, res, next) ->
    Account.request 'all', (err, founds) ->
        return next err if err
        res.accounts = founds
        next()

# change an account
module.exports.edit = (req, res, next) ->

    updated = new Account req.body

    # check params before applying changes
    updated.testConnections (err) ->
        return next err if err

        changes = _.pick req.body, Object.keys Account.schema
        req.account.updateAttributes changes, (err, updated) ->
            res.account = updated
            next err

# delete an account
module.exports.remove = (req, res, next) ->
    req.account.destroyEverything (err) ->
        return next err if err
        res.status(204).end()
