_ = require 'lodash'
Account = require '../models/account'
{AccountConfigError, HttpError} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'accounts:controller')

# create an account
# and lauch fetching of this account mails
module.exports.create = (req, res, next) ->
    # @TODO : validate req.body
    data = req.body
    Account.createIfValid data
    .then (account) -> account.toObjectWithMailbox()
    .then (account) -> res.send 201, account
    .catch AccountConfigError, (err) ->
        log.warn err.toString()
        log.warn err.stack.split("\n")[2]
        res.send 400,
            name: err.name
            field: err.field
            stack: err.stack
            error: true
    .catch next

# fetch an account by id, add it to the request
module.exports.fetch = (req, res, next) ->
    Account.findPromised req.params.accountID
    .then (account) ->
        if account then req.account = account
        else throw new HttpError 404, 'Not Found'
    .nodeify next

# fetch the list of all Accounts
# include the account mailbox tree
module.exports.list = (req, res, next) ->
    Account.requestPromised 'all'
    .map (account) -> account.toObjectWithMailbox()
    .then (accounts) -> res.send 200, accounts
    .catch next

# get an account with its mailboxes
module.exports.details = (req, res, next) ->
    req.account.toObjectWithMailbox()
    .then -> res.send 200, req.account
    .catch next

# change an account
module.exports.edit = (req, res, next) ->
    # @TODO : may be only allow changes to label, unless connection broken

    changes = _.pick req.body,
        'label', 'login', 'password', 'name', 'account_type'
        'smtpServer', 'smtpPort', 'smtpSSL', 'smtpTLS',
        'imapServer', 'imapPort', 'imapSSL', 'imapTLS',
        'draftMailbox', 'sentMailbox', 'trashMailbox'

    req.account.updateAttributesPromised changes
    .then (account) -> account.toObjectWithMailbox()
    .then (account) -> res.send 200, account
    .catch next

# delete an account
module.exports.remove = (req, res, next) ->
    # @TODO, handle clean up of boxes & mails
    req.account.destroyEverything()
    .then -> res.send 204
    .catch next
