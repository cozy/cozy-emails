async = require 'async'

Account = require '../models/account'
Imap = require '../processes/imap'
{HttpError} = require '../utils/errors'

module.exports.create = (req, res, next) ->
    # @TODO : validate req.body
    account = req.body
    Imap.getMailboxes account
        .then (mailboxes) -> account.mailboxes = mailboxes
        .then (mailboxes) -> Account.createPromised account
        .then (account)   -> res.send 201, Account.clientVersion account
        .catch next

module.exports.list = (req, res, next) ->
    Account.getAllPromised()
        .then (accounts) ->
            res.send 200, accounts.map Account.clientVersion
        .catch next

module.exports.fetch = (req, res, next) ->
    Account.findPromised req.params.accountID
        .then (account) ->
            if account then req.account = account
            else throw new HttpError 404, 'Not Found'
        .nodeify next

module.exports.details = (req, res, next) ->
    res.send 200, Account.clientVersion req.account

module.exports.edit = (req, res, next) ->
    # @TODO : validate req.body

    # we don't take all the fields, only some of them are editable
    changes =
        label: req.body.label
        login: req.body.login
        password: req.body.password
        smtpServer: req.body.smtpServer
        smtpPort: req.body.smtpPort
        imapServer: req.body.imapServer
        imapPort: req.body.imapPort

    req.account.updateAttributesPromised(changes)
        .then (account) -> res.send 200, Account.clientVersion account
        .catch next

module.exports.remove = (req, res, next) ->
    # @TODO, handle clean up of tree & mails
    ids = req.account.mailboxIds()
    req.account.destroyPromised()
        .then -> res.send 204
        .catch next
