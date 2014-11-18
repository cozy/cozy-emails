americano = require 'americano-cozy'

# Public: Account
# a {JugglingDBModel} for an account
class Account # make biscotto happy

module.exports = Account = americano.getModel 'Account',
    label: String               # human readable label for the account
    name: String                # user name to put in sent mails
    login: String               # IMAP & SMTP login
    password: String            # IMAP & SMTP password
    accountType: String         # "IMAP" or "TEST"
    smtpServer: String          # SMTP host
    smtpPort: Number            # SMTP port
    smtpSSL: Boolean            # Use SSL
    smtpTLS: Boolean            # Use STARTTLS
    imapServer: String          # IMAP host
    imapPort: Number            # IMAP port
    imapSSL: Boolean            # Use SSL
    imapTLS: Boolean            # Use STARTTLS
    inboxMailbox: String        # INBOX Maibox id
    draftMailbox: String        # \Draft Maibox id
    sentMailbox: String         # \Sent Maibox id
    trashMailbox: String        # \Trash Maibox id
    junkMailbox: String         # \Junk Maibox id
    allMailbox: String          # \All Maibox id
    favorites: (x) -> x         # [String] Maibox id of displayed boxes



# There is a circular dependency between ImapProcess & Account
# node handle if we require after module.exports definition
nodemailer  = require 'nodemailer'
Mailbox     = require './mailbox'
Promise     = require 'bluebird'
Message     = require './message'
{AccountConfigError} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'models:account')
_ = require 'lodash'

Account::isTest = ->
    @accountType is 'TEST'

# Public: refresh all accounts
#
# Returns {Promise} for task completion
Account.refreshAllAccounts = (limit, onlyFavorites) ->
    Account.requestPromised 'all'
    .serie (account) ->
        return null if account.isTest()
        account.imap_fetchMails(limit, onlyFavorites)


# Public: get the account as POJO
# including the client's mailboxes tree
#
# Returns {Promise} for the POJO
Account::toObjectWithMailbox = ->
    Mailbox.getClientTree @id
    .then (mailboxes) =>
        rawObject = @toObject()
        rawObject.favorites = rawObject.favorites or []
        rawObject.mailboxes = mailboxes
        return rawObject

# Public: fetch the mailbox tree of a new {Account}
# if the fetch succeeds, create the account and mailboxes in couch
# else throw an {AccountConfigError}
# returns fast once the account and mailboxes has been created
# in the background, proceeds to download mails
#
# data - account parameters
#
# Returns {Promise} promise for the created {Account}
Account.createIfValid = (data) ->

    account = new Account data

    pAccountCredentialsOK = if account.isTest()
        Promise.resolve true
    else
        account.testSMTPConnection()
        .then -> account.testIMAPConnection()

    pAccountReady = pAccountCredentialsOK
    .then ->
        # should be account.save() but juggling
        Account.createPromised account
        .then (created) -> account = created

    .then -> account.imap_refreshBoxes()
    # find special mailboxes (sent, draft ...)
    .spread (boxesToFetch, boxesToDestroy) ->
        # disregard boxes toDestroy as there cant be any now
        account.imap_scanBoxesForSpecialUse boxesToFetch


    # in a detached chain, fetch the Account
    pAccountReady.then ->
        # first fetch 100 mails from each box
        account.imap_refreshBoxes()
        .then -> account.imap_fetchMails 100
        .then -> account.imap_fetchMails()
        .catch (err) -> log.error "FETCH MAIL FAILED", err.stack or err

    # returns once the account is ready (do not wait for mails)
    return pAccountReady


# Public: remove a box from this account references
# ie. favorites & special use attributes
# used when deleting a box
#
# boxid - id of the box to forget
#
# Returns a {Promise} for the updated account
Account::forgetBox = (boxid) ->
    change = false
    for attribute in Object.keys Mailbox.RFC6154 when @[attribute] is boxid
        @[attribute] = null
        change = true

    if boxid in @favorites
        @favorites = _.without @favorites, boxid
        change = true

    return if change then @savePromised()
    else Promise.resolve this


# Public: destroy an account and all messages within cozy
#
# returns fast after destroying account
# in the background, proceeds to erase all boxes & message
#
# Returns a {Promise} for account destroyed completion
Account::destroyEverything = ->
    accountDestroyed = @destroyPromised()

    accountID = @id

    # this runs in the background
    accountDestroyed
    .then -> Mailbox.destroyByAccount accountID
    .then -> Message.safeDestroyByAccountID accountID

    # return as soon as the account is destroyed
    # (the interface will be correct)
    return accountDestroyed

require './account_imap'
require './account_smtp'
Promise.promisifyAll Account, suffix: 'Promised'
Promise.promisifyAll Account::, suffix: 'Promised'
