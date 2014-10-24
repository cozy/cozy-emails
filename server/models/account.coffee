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

Account::isTest = ->
    @accountType is 'TEST'

# Public: refresh all accounts
#
# Returns {Promise} for task completion
Account.refreshAllAccounts = ->
    Account.requestPromised 'all'
    .serie (account) ->
        return null if account.isTest()
        account.imap_fetchMails()


# Public: include the mailboxes tree on this account instance
#
# Returns {Promise} for the account itself
Account::toObjectWithMailbox = ->
    Mailbox.getClientTree @id
    .then (mailboxes) =>
        rawObject = @toObject()
        rawObject.mailboxes = mailboxes
        return rawObject

# Public: fetch the mailbox tree of a new {Account}
# if the fetch succeeds, create the account and mailbox in couch
#
# data - account parameters
#
# Returns {Promise} promise for the created {Account}, boxes included
Account.createIfValid = (data) ->

    account = new Account data

    pBoxes = if account.isTest()
        Promise.resolve []
    else
        account.testSMTPConnection()
        .then -> account.imap_getBoxes data

    pAccountReady = pBoxes
    # save now so we have an account id
    .tap ->
        # should be account.save() but juggling
        Account.createPromised account
        .then (created) -> account = created

    # save boxes, we need their IDs
    .map (box) ->
        box.accountID = account.id
        Mailbox.createPromised box

    # find special mailboxes
    .then (boxes) ->
        account.imap_scanBoxesForSpecialUse boxes

    # in a detached chain, fetch the Account
    pAccountReady.then (account) ->
        # first fetch 100 mails from each box
        account.imap_fetchMails 100
        # then fetch the rest
        .then -> account.imap_fetchMails()
        .catch (err) -> log.error "FETCH MAIL FAILED", err.stack or err

    # returns once the account is ready (do not wait for mails)
    return pAccountReady


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
