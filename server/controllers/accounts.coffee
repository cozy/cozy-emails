_ = require 'lodash'
Account = require '../models/account'
{AccountConfigError, HttpError, NotFound} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'accounts:controller')
{NotFound} = require '../utils/errors'
async = require 'async'




# fetch an account by id, add it to the request
module.exports.fetch = (req, res, next) ->
    id = req.params.accountID or
         req.body.accountID or
         req.mailbox.accountID or
         req.message.accountID

    Account.find id, (err, found) ->
        return next new HttpError 404, err if err
        return next new NotFound "Acccount #{id}" unless found
        req.account = found
        next()

module.exports.format = (req, res, next) ->
    log.info "FORMATTING ACCOUNT"
    res.account.toClientObject (err, formated) ->
        log.info "SENDING ACCOUNT"
        return next err if err
        res.send formated

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

# check account parameters
module.exports.check = (req, res, next) ->
    Account.checkParams req.body, (err) ->
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
    # @TODO : may be only allow changes to label, unless connection broken

    changes = _.pick req.body,
        'label', 'login', 'password', 'name', 'account_type'
        'smtpServer', 'smtpPort', 'smtpSSL', 'smtpTLS',
        'smtpLogin', 'smtpPassword', 'smtpMethod',
        'imapServer', 'imapPort', 'imapSSL', 'imapTLS',
        'draftMailbox', 'sentMailbox', 'trashMailbox'

    # check params before applying changes
    Account.checkParams changes, (err) ->
        return next err if err

        req.account.updateAttributes changes, (err, updated) ->
            res.account = updated
            next err

# delete an account
module.exports.remove = (req, res, next) ->
    # @TODO, handle clean up of boxes & mails
    req.account.destroyEverything (err) ->
        return next err if err
        res.status(204).end()
