_ = require 'lodash'
Account = require '../models/account'
{AccountConfigError} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'accounts:controller')
async = require 'async'
notifications = require '../utils/notifications'
ramStore = require '../models/store_account_and_boxes'

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
    # when checking, we try to connect to IMAP server with the raw
    # data sent by client, so we need to override here login with
    # imapLogin if present
    if req.body.imapLogin
        req.body.login = req.body.imapLogin
    tmpAccount = new Account _.pick req.body, Object.keys Account.schema
    tmpAccount.testConnections (err) ->
        return next err if err
        res.send check: 'ok'

# change an account
module.exports.edit = (req, res, next) ->

    accountInstance = ramStore.getAccount(req.params.accountID)
    changes = _.pick req.body, Object.keys Account.schema
    updated = new Account changes
    unless updated.password and updated.password isnt ''
        updated.password = accountInstance.password

    # check params before applying changes
    updated.testConnections (err) ->
        return next err if err

        accountInstance.updateAttributes changes, (err, updated) ->
            return next err if err
            res.send accountInstance

# delete an account
module.exports.remove = (req, res, next) ->
    accountInstance = ramStore.getAccount(req.params.accountID)
    accountInstance.destroy (err) ->
        return next err if err
        res.status(204).end()
