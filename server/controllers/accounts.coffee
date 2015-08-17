_ = require 'lodash'
Account = require '../models/account'
{AccountConfigError} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'accounts:controller')
async = require 'async'
notifications = require '../utils/notifications'
ramStore = require '../models/store_account_and_boxes'
Scheduler = require '../processes/_scheduler'

# create an account
# and lauch fetching of this account mails
module.exports.create = (req, res, next) ->
    # @TODO : validate req.body
    account = new Account _.pick req.body, Object.keys Account.schema
    async.series [
        (cb) ->
            log.debug "create#testConnections"
            account.testConnections cb

        (cb) ->
            log.debug "create#cozy"
            Account.create account, (err, created) ->
                return cb err if err
                account = created
                cb null
        (cb) ->
            account.initialize cb

    ], (err) ->
        return next err if err
        res.send ramStore.getAccountClientObject account.id
        Scheduler.startAccountRefresh(account.id) # will start a refresh

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
            res.send ramStore.getAccountClientObject accountInstance.id

# delete an account
module.exports.remove = (req, res, next) ->
    accountInstance = ramStore.getAccount(req.params.accountID)
    accountInstance.destroy (err) ->
        return next err if err
        Scheduler.orphanRemovalDebounced()
        res.status(204).end()
