_ = require 'lodash'
Account = require '../models/account'
{AccountConfigError} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'accounts:controller')
async = require 'async'
notifications = require '../utils/notifications'
ramStore = require '../models/store_account_and_boxes'
Scheduler = require '../processes/_scheduler'
MailboxRefresh = require '../processes/mailbox_refresh'
patchConversation = require '../patchs/conversation'

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

        favoriteBoxes = ramStore.getFavoriteMailboxesByAccount account.id
        allBoxes = ramStore.getMailboxesByAccount account.id

        # after the http request have been replied, fire up a refresh
        # of this account
        async.series [
            # fetch 100 messages for each box
            (cb) ->
                refreshes = favoriteBoxes.map (mailbox) ->
                    new MailboxRefresh {mailbox, limitByBox: 100}

                Scheduler.scheduleMultiple refreshes, cb

            # fetch all the other messages (very long)
            (cb) ->
                refreshes = allBoxes.map (mailbox) ->
                        new MailboxRefresh {mailbox, storeHighestModSeq: true}

                Scheduler.scheduleMultiple refreshes, cb

            # message fetched in first refresh might not be in proper conv
            # @TODO : apply patch only to messages from first refresh ?
            (cb) ->
                patchConversation.patchOneAccount account, cb

        ], (err) ->
            log.error err if err
            log.info "Account #{account?.label} import complete"

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
