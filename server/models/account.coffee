americano = require 'americano-cozy'

# Public: Account
# a {JugglingDBModel} for an account
class Account # make biscotto happy

module.exports = Account = americano.getModel 'Account',
    label: String               # human readable label for the account
    name: String                # user name to put in sent mails
    login: String               # IMAP & SMTP login
    password: String            # IMAP & SMTP password
    smtpServer: String          # SMTP host
    smtpPort: Number            # SMTP port
    imapServer: String          # IMAP host
    imapPort: Number            # IMAP port
    inboxMailbox: String        # INBOX Maibox id
    draftMailbox: String        # \Draft Maibox id
    sentMailbox: String         # \Sent Maibox id
    trashMailbox: String        # \Trash Maibox id
    junkMailbox: String         # \Junk Maibox id
    allMailbox: String          # \All Maibox id
    favorites: (x) -> x         # [String] Maibox id of displayed boxes
    mailboxes: (x) -> x         # [BLAMEJDB] mailboxes should not saved

# There is a circular dependency between ImapProcess & Account
# node handle if we require after module.exports definition
nodemailer = require 'nodemailer'
Mailbox = require './mailbox'
ImapProcess = require '../processes/imap_processes'
Promise = require 'bluebird'
{WrongConfigError} = require '../utils/errors'
log = require('../utils/logging')(prefix: 'models:account')

# Public: refresh all accounts
# 
# Returns {Promise} for task completion
Account.refreshAllAccounts = ->
    allAccounts = Account.requestPromised 'all'
    Promise.serie allAccounts, (account) ->
        ImapProcess.fetchAccount account

# Public: refresh this account
# 
# Returns a {Promise} for task completion
Account::fetchMails = ->
    ImapProcess.fetchAccount this

# Public: include the mailboxes tree on this account instance
# 
# Returns {Promise} for the account itself
Account::includeMailboxes = ->
    Mailbox.getClientTree @id
    .then (mailboxes) =>
        @mailboxes = mailboxes
    .return this

# Public: fetch the mailbox tree of a new {Account}
# if the fetch succeeds, create the account and mailbox in couch
# 
# Returns {Promise} promise for the created {Account}, boxes included
Account.createIfValid = (data) ->
    
    accountAndBoxesCreated = ImapProcess.fetchBoxesTree data
    .then (rawBoxesTree) ->
        # We managed to get boxes, login settings are OK
        # create Account and Mailboxes
        log.info "GOT BOXES", rawBoxesTree
        # pass rawBoxesTree down the chain
        Promise.all [ rawBoxesTree, Account.createPromised data ]

    .spread (rawBoxesTree, account) ->
        Mailbox.createBoxesFromImapTree account.id, rawBoxesTree    
        .then (specialUses) -> 
            account.updateAttributesPromised specialUses

    # fork the promise
    # return from this function a fast promise for account with boxes
    returnValue = accountAndBoxesCreated.then (account) ->
        log.info "CREATED ACCOUNT & BOXES"
        return account.includeMailboxes()

    # in a detached chain, fetch the Account
    accountAndBoxesCreated.then (account) ->
        # first fetch 15 mails from each box
        ImapProcess.fetchAccount account, 15
        .then -> ImapProcess.fetchAccount account
        .catch (err) -> console.log "FETCH MAIL FAILED", err.stack

    return returnValue

# Public: send a message using this account SMTP config
# 
# message - a raw message
# callback - a (err, info) callback with the following parameters
#            :err
#            :info the nodemailer's info
# 
# Returns void
Account::sendMessage = (message, callback) ->
    transport = nodemailer.createTransport
        port: @smtpPort
        host: @smtpServer
        auth: 
            user: @login
            pass: @password

    transport.sendMail message, callback


Promise.promisifyAll Account, suffix: 'Promised'
Promise.promisifyAll Account::, suffix: 'Promised'
