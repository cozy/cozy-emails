Immutable = require 'immutable'
{MessageActions, AccountActions} = require '../constants/app_constants'

Routes = require '../routes'
Mailbox = require './mailbox'

Account = Immutable.Record

    id: undefined

    label: undefined
    name: undefined
    login: undefined
    password: undefined
    accountType: undefined
    oauthProvider: undefined
    oauthAccessToken: undefined
    oauthRefreshToken: undefined
    oauthTimeout: undefined
    initialized: undefined
    smtpServer: undefined
    smtpPort: undefined
    smtpSSL: undefined
    smtpTLS: undefined
    smtpLogin: undefined
    smtpPassword: undefined
    smtpMethod: undefined
    imapLogin: undefined
    imapServer: undefined
    imapPort: undefined
    imapSSL: undefined
    imapTLS: undefined
    inboxMailbox: undefined
    flaggedMailbox: undefined
    draftMailbox: undefined
    sentMailbox: undefined
    trashMailbox: undefined
    junkMailbox: undefined
    allMailbox: undefined
    favorites: undefined
    patchIgnored: undefined
    supportRFC4551: undefined
    signature: undefined
    _passwordStillEncrypted: undefined

    mailboxes: Immutable.Map()


# @TODO : this is wrong, label is user defined value
Account::isGmail = ->
    @get('label')?.toLowerCase().indexOf 'gmail'

Account.from = (rawAccount) ->
    account = new Account(rawAccount)

    # transform the mailboxes
    mailboxes = Immutable.Iterable(rawAccount.mailboxes)
        .toKeyedSeq()
        .map (mailbox) ->
            mailbox = Mailbox.from mailbox, account
        # Mailbox.from can return null
        .filter (value) -> value?
        .toOrderedMap()
        # index by ID
        .mapKeys (index, mailbox) -> mailbox.get('id')
        # OVH issue : some accounts have two inboxes
        .filter (mailbox) ->
            not mailbox.isInbox() or
            mailbox.get('id') is account.get('inboxMailbox')
        # sort them by order and then tree
        .sort Mailbox.sortFunction

    # trueInbox = mailboxes.get(account.get('inboxMailbox'))

    # mailboxes = mailboxes.map (mailbox) ->
    #     if mailbox.id is 'mailbox-1d0b1ebc-49ae-a505-e738-3e696a60d256'
    #     if mailbox.hasAttrib(MailboxFlags.INBOX) and
    #     not mailbox.childOf(trueInbox)
    #         return mailbox.removeAttrib(MailboxFlags.INBOX)
    #     else
    #         return mailbox


    return account.set 'mailboxes', mailboxes

Account::isInboxOrChild = (mailbox) ->
    inboxMailbox = @mailboxes.get @get('inboxMailbox')
    return mailbox is inboxMailbox or mailbox.childOf(inboxMailbox)

Account::addMailbox = (mailbox) ->
    # mailox instanceof Mailbox
    mailboxID = mailbox.get('id')
    if mailbox.isInbox() and mailboxID isnt @get('inboxMailbox')
        return @ # discard this box
    else
        return @setIn ['mailboxes', mailbox.get('id')], mailbox

Account::makeInboxURL = ->
    return Routes.makeURL MessageActions.SHOW_ALL,
        accountID: @get('id')
        mailboxID: @get('inboxMailbox')
        resetFilter: true
    , false

Account::makeConfigURL = ->
    return Routes.makeURL AccountActions.EDIT,
        accountID: @get('id')
        tab: 'account'
    , false

Account::getInboxMailboxes = ->
    @get('mailboxes').filter (mailbox) =>
        @isInboxOrChild mailbox, true

Account::getOtherMailboxes = ->
    @get('mailboxes').filter (mailbox) =>
        not @isInboxOrChild mailbox, true

Account::validateAndSet = (changes) ->

module.exports = Account
