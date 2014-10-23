americano = require 'americano-cozy'

# Public: Account
# a {JugglingDBModel} for an account
class Account # make biscotto happy

module.exports = Account = americano.getModel 'Account',
    label: String               # human readable label for the account
    name: String                # user name to put in sent mails
    login: String               # IMAP & SMTP login
    password: String            # IMAP & SMTP password
    accountType: String         # "IMAP3" or "TEST"
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
ImapProcess = require '../processes/imap_processes'
Promise     = require 'bluebird'
Message     = require './message'
{AccountConfigError} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'models:account')

# Public: refresh all accounts
#
# Returns {Promise} for task completion
Account.refreshAllAccounts = ->
    allAccounts = Account.requestPromised 'all'
    Promise.serie allAccounts, (account) ->
        if not account.accountType is 'TEST'
            ImapProcess.fetchAccount account

# Public: refresh this account
#
# Returns a {Promise} for task completion
Account::fetchMails = ->
    ImapProcess.fetchAccount this

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

    pBoxes = if data.accountType is 'TEST' then Promise.resolve []
    else
        Account.testSMTPConnection data
        .then -> ImapProcess.fetchBoxesTree data

    # We managed to get boxes, login settings are OK
    pAccount = pBoxes.then ->
        Account.createPromised data

    # scan account mailboxes for special-use
    pSpecialUseBoxes = Promise.join pAccount, pBoxes, (account, boxes) ->
        Mailbox.createBoxesFromImapTree account.id, boxes

    # save special-use into the account
    pAccountReady = Promise.join pAccount, pSpecialUseBoxes, (account, specialUses) ->
        account.updateAttributesPromised specialUses

    pAccountReady.then (account) ->
        # in a detached chain, fetch the Account
        # first fetch 100 mails from each box
        ImapProcess.fetchAccount account, 100
        # then fetch the rest
        .then -> ImapProcess.fetchAccount account
        .catch (err) -> log.error "FETCH MAIL FAILED", err

    # returns once the account is ready (do not wait for mails)
    return pAccountReady.then (account) -> account.includeMailboxes()



# Public: destroy an account and all messages within
# returns fast after destroying account
# in the background, proceeds to erase all boxes & message
#
# Returns a {Promise} for account destroyed completion
Account::destroyEverything = ->
    accountDestroyed = @destroyPromised()

    accountID = @id

    # this runs in the background
    accountDestroyed.then ->
        Mailbox.rawRequestPromised 'treemap',
            startkey: [accountID]
            endkey: [accountID, {}]

    .map (row) ->
        new Mailbox(id: row.id).destroy()
        .catch (err) -> log.warn "FAIL TO DELETE BOX", row.id

    .then ->
        Message.safeDestroyByAccountID accountID

    # return as soon as the account is destroyed
    # (the interface will be correct)
    return accountDestroyed



require './account_smtp'
Promise.promisifyAll Account, suffix: 'Promised'
Promise.promisifyAll Account::, suffix: 'Promised'
