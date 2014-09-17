async = require 'async'

Account = require '../models/account'
Mailbox = require '../models/mailbox'
Imap = require '../processes/imap_processes'
_ = require 'lodash'
{WrongConfigError, HttpError} = require '../utils/errors'

# create an account
# and lauch fetching of this account mails
module.exports.create = (req, res, next) ->
    # @TODO : validate req.body
    data = req.body
    accountCreated = Account.createIfValid data

    accountCreated.then (account) -> res.send 201, account
    .catch WrongConfigError, (err) ->
        throw new HttpError 401, err
    .catch next

    # outside of this request lifecycle, we fetch mails
    accountCreated.then (account) ->
        account.fetchMails()
        .catch (err) -> console.log "FETCH MAIL FAILED", err

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
    Account.listWithMailboxes()
    .then (accounts) -> res.send 200, accounts
    .catch next

# get an account with its mailboxes
module.exports.details = (req, res, next) ->
    req.account.includeMailboxes()
        .then -> res.send 200, req.account
        .catch next

# change an account
module.exports.edit = (req, res, next) ->
    # @TODO : may be only allow changes to label, unless connection broken

    changes = _.pick req.body, 'label', 'login', 'password',
        'smtpServer', 'smtpPort', 'imapServer', 'imapPort'

    req.account.updateAttributesPromised changes
        .then (account) -> res.send 200, account
        .catch next

# delete an account
module.exports.remove = (req, res, next) ->
    # @TODO, handle clean up of boxes & mails
    req.account.destroyPromised()
        .then -> res.send 204
        .catch next
