cozydb = require 'cozydb'

module.exports = Account = cozydb.getModel 'Account',
    label: String               # human readable label for the account
    name: String                # user name to put in sent mails
    login: String               # IMAP & SMTP login
    password: String            # IMAP & SMTP password
    accountType: String         # "IMAP" or "TEST"
    smtpServer: String          # SMTP host
    smtpPort: Number            # SMTP port
    smtpSSL: Boolean            # Use SSL
    smtpTLS: Boolean            # Use STARTTLS
    smtpLogin: String           # SMTP login, if different from default
    smtpPassword: String        # SMTP password, if different from default
    smtpMethod: String          # SMTP Auth Method
    imapServer: String          # IMAP host
    imapPort: Number            # IMAP port
    imapSSL: Boolean            # Use SSL
    imapTLS: Boolean            # Use STARTTLS
    inboxMailbox: String        # INBOX Maibox id
    flaggedMailbox: String      # \Flag Mailbox id
    draftMailbox: String        # \Draft Maibox id
    sentMailbox: String         # \Sent Maibox id
    trashMailbox: String        # \Trash Maibox id
    junkMailbox: String         # \Junk Maibox id
    allMailbox: String          # \All Maibox id
    favorites: [String]         # [String] Maibox id of displayed boxes



# There is a circular dependency between ImapProcess & Account
# node handle if we require after module.exports definition
Mailbox     = require './mailbox'
Message     = require './message'
Compiler    = require 'nodemailer/src/compiler'
ImapPool = require '../imap/pool'
ImapReporter = require '../imap/reporter'
{AccountConfigError} = require '../utils/errors'
nodemailer  = require 'nodemailer'
SMTPConnection = require 'nodemailer/node_modules/' +
    'nodemailer-smtp-transport/node_modules/smtp-connection'
log = require('../utils/logging')(prefix: 'models:account')
_ = require 'lodash'
async = require 'async'
CONSTANTS = require '../utils/constants'
require('../utils/socket_handler').wrapModel Account, 'account'


Account::doASAP = (operation, callback) ->
    ImapPool.get(@id).doASAP operation, callback

Account::isTest = ->
    @accountType is 'TEST'

Account::isRefreshing = ->
    ImapPool.get(@id).isRefreshing

Account::setRefreshing = (value) ->
    ImapPool.get(@id).isRefreshing = value

# Public: refresh all accounts
#
Account.refreshAllAccounts = (limit, onlyFavorites, callback) ->
    Account.request 'all', (err, accounts) ->
        return callback err if err
        options =
            accounts: accounts
            limitByBox: limit
            onlyFavorites: onlyFavorites
            firstImport: false
        Account.refreshAccounts options, callback


Account.removeOrphansAndRefresh = (limitByBox, onlyFavorites, callback) ->
    Account.request 'all', (err, accounts) ->
        return callback err if err
        existingAccountIDs = accounts.map (account) -> account.id
        Mailbox.removeOrphans existingAccountIDs, (err, existingMailboxIDs) ->
            return callback err if err
            Message.removeOrphans existingMailboxIDs, (err) ->
                return callback err if err
                options =
                    accounts: accounts
                    limitByBox: limitByBox
                    onlyFavorites: onlyFavorites
                    firstImport: false
                    periodic: CONSTANTS.REFRESH_INTERVAL
                Account.refreshAccounts options, callback


Account.refreshAccounts = (options, callback) ->
    {accounts, limitByBox, onlyFavorites, firstImport, periodic} = options
    async.eachSeries accounts, (account, cb) ->
        log.debug "refreshing account #{account.label}"
        return cb null if account.isTest()
        return cb null if account.isRefreshing()
        account.imap_fetchMails limitByBox, onlyFavorites, firstImport, (err) ->
            log.debug "done refreshing account #{account.label}"
            if err
                log.error "CANT REFRESH ACCOUNT", account.id, account.label, err
            # refresh all accounts even if one fails
            cb null
    , (err) ->
        if periodic?
            setTimeout ->
                log.debug "doing periodic refresh"
                # periodic refresh should only check new messages on favorites mailboxes
                options.onlyFavorites = true
                options.limitByBox    = CONSTANTS.LIMIT_BY_BOX
                Account.refreshAccounts options
            , periodic
        if callback?
            callback err


# Public: fetch the mailbox tree of a new {Account}
# if the fetch succeeds, create the account and mailboxes in couch
# else throw an {AccountConfigError}
# returns fast once the account and mailboxes has been created
# in the background, proceeds to download mails
#
# data - account parameters
#
# Returns  {Account}
Account.createIfValid = (data, callback) ->

    account = new Account data
    toFetch = null

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
            log.debug "create#refreshBoxes"
            account.imap_refreshBoxes (err, boxes) ->
                return cb err if err
                toFetch = boxes
                cb null

        (cb) ->
            log.debug "create#scan"
            account.imap_scanBoxesForSpecialUse toFetch, cb
    ], (err) ->
        return callback err if err
        callback null, account


# Public: check account parameters
#
# data - account parameters
#
# Returns  {Account}
Account.checkParams = (data, callback) ->
    account = new Account data
    account.testConnections callback


Account::testConnections = (callback) ->
    return callback null if @isTest()
    @testSMTPConnection (err) =>
        return callback err if err
        ImapPool.test this, (err) ->
            return callback err if err
            callback null


# Public: remove a box from this account references
# ie. favorites & special use attributes
# used when deleting a box
#
# boxid - id of the box to forget
#
# Returns a the updated account
Account::forgetBox = (boxid, callback) ->
    changes = {}
    for attribute in Object.keys Mailbox.RFC6154 when @[attribute] is boxid
        changes[attribute] = null

    if boxid in @favorites
        changes.favorites = _.without @favorites, boxid

    if Object.keys(changes).length
        @updateAttributes changes, callback
    else
        callback null


# Public: destroy an account and all messages within cozy
#
# returns fast after destroying account
# in the background, proceeds to erase all boxes & message
#
# Returns a completion
Account::destroyEverything = (callback) ->
    async.series [
        (cb) => @destroy cb
        (cb) => Mailbox.destroyByAccount @id, cb
        (cb) => Message.safeDestroyByAccountID @id, cb
    ], callback

Account::toClientObject = (callback) ->
    rawObject = @toObject()
    rawObject.favorites ?= []

    Mailbox.rawRequest 'treeMap',
        startkey: [@id]
        endkey: [@id, {}]
        include_docs: true
    , (err, rows) ->
        return callback err if err
        rawObject.mailboxes = rows.map (row) ->
            row.doc.id ?= row.id
            _.pick row.doc, 'id', 'label', 'attribs', 'tree'

        Mailbox.getCounts null, (err, counts) ->
            return callback err if err
            for box in rawObject.mailboxes
                count = counts[box.id] or {total: 0, unread: 0, recent: 0}
                box.nbTotal  = count.total
                box.nbUnread = count.unread
                box.nbRecent = count.recent

            callback null, rawObject

Account.clientList = (callback) ->
    Account.request 'all', (err, accounts) ->
        return callback err if err
        async.map accounts, (account, cb) ->
            account.toClientObject cb
        , callback


# static function, we have 1 ImapScheduler by Account

Account::imap_getBoxes = (callback) ->
    log.debug "getBoxes"
    @doASAP (imap, cb) ->
        imap.getBoxesArray cb
    , (err, boxes) ->
        return callback err, boxes or []

Account::imap_refreshBoxes = (callback) ->
    log.debug "imap_refreshBoxes"
    account = this

    async.series [
        (cb) => Mailbox.getBoxes @id, cb
        (cb) => @imap_getBoxes cb
    ], (err, results) ->
        log.debug "refreshBoxes#results", results
        return callback err if err
        [cozyBoxes, imapBoxes] = results

        toFetch = []
        toDestroy = []
        # find new imap boxes
        boxToAdd = imapBoxes.filter (box) ->
            not _.findWhere(cozyBoxes, path: box.path)

        # discrimate cozyBoxes to fetch and to remove
        for cozyBox in cozyBoxes
            if _.findWhere(imapBoxes, path: cozyBox.path)
                toFetch.push cozyBox
            else
                toDestroy.push cozyBox

        log.debug "refreshBoxes#results2"


        async.eachSeries boxToAdd, (box, cb) ->
            log.debug "refreshBoxes#creating", box.label
            box.accountID = account.id
            Mailbox.create box, (err, created) ->
                return cb err if err
                toFetch.push created
                cb null
        , (err) ->
            return callback err if err
            callback null, toFetch, toDestroy


# Public: refresh one account
# register a 'account-fetch' task in {ImapReporter}
#
# limitByBox - the maximum {Number} of message to fetch at once for each box
# onlyFavorites - {Boolean} fetch messages only for favorite mailboxes
#
# Returns a task completion
Account::imap_fetchMails = (limitByBox, onlyFavorites, firstImport, callback) ->
    log.debug "account#imap_fetchMails", limitByBox, onlyFavorites
    account = this
    account.setRefreshing true

    onlyFavorites ?= false

    @imap_refreshBoxes (err, toFetch, toDestroy) ->
        account.setRefreshing(false) if err
        return callback err if err

        if onlyFavorites
            toFetch = toFetch.filter (box) -> box.id in account.favorites

        toFetch = toFetch.filter (box) -> box.isSelectable()

        log.info "FETCHING ACCOUNT #{account.label} : #{toFetch.length} BOXES"
        log.info "   ", toDestroy.length, "BOXES TO DESTROY"
        numToFetch = toFetch.length + 1
        reporter = ImapReporter.accountFetch account, numToFetch, firstImport

        # fetch INBOX first
        toFetch.sort (a, b) ->
            return if a.label is 'INBOX' then -1
            else return 1

        async.eachSeries toFetch, (box, cb) ->
            box.imap_fetchMails limitByBox, firstImport, (err) ->
                # @TODO : Figure out how to distinguish a mailbox that
                # is not selectable but not marked as such. In the meantime
                # dont pop the error to the client
                if err and -1 is err.message?.indexOf "Mailbox doesn't exist"
                    reporter.onError err
                reporter.addProgress 1
                # dont interrupt the loop if one fail
                cb null

        , (err) ->
            account.setRefreshing(false) if err
            return callback err if err
            log.debug "account#imap_fetchMails#DONE"

            async.eachSeries toDestroy, (box, cb) ->
                box.destroyAndRemoveAllMessages cb

            , (err) ->
                account.setRefreshing false
                reporter.onDone()
                callback null

Account::imap_fetchMailsTwoSteps = (callback) ->
    log.debug "account#imap_fetchMails2Steps"
    @imap_fetchMails 100, true, true, (err) =>
        return callback err if err
        @imap_fetchMails null, false, true, (err) ->
            return callback err if err
            callback null

# Public: create a mail in the given box
# used for drafts
#
# box - the {Mailbox} to create mail into
# message - a {Message} to create
#
# Returns a the box & UID of the created mail
Account::imap_createMail = (box, message, callback) ->

    # compile the message to text
    # @todo, promisfy somewhere else

    mailbuilder = new Compiler(message).compile()
    mailbuilder.build (err, buffer) =>
        return callback err if err

        @doASAP (imap, cb) ->
            imap.append buffer,
                mailbox: box.path
                flags: message.flags
            , cb

        , (err, uid) ->
            return callback err if err
            callback null, uid

Account::imap_scanBoxesForSpecialUse = (boxes, callback) ->
    useRFC6154 = false
    inboxMailbox = null
    boxAttributes = Object.keys Mailbox.RFC6154

    changes = {}

    boxes.map (box) ->
        type = box.RFC6154use()
        if box.isInbox()
            # save it in scope, so we dont erase it
            inboxMailbox = box.id

        else if type
            unless useRFC6154
                useRFC6154 = true
                # remove previous guesses
                for attribute in boxAttributes
                    changes[attribute] = null
            log.debug 'found', type
            changes[type] = box.id

        # do not attempt fuzzy match if the server uses RFC6154
        else if not useRFC6154 and type = box.guessUse()
            log.debug 'found', type, 'guess'
            changes[type] = box.id

        return box

    # pick the default 4 favorites box
    priorities = [
        'inboxMailbox', 'allMailbox',
        'sentMailbox', 'draftMailbox'
    ]

    changes.inboxMailbox = inboxMailbox
    changes.favorites = []

    # see if we have some of the priorities box
    for type in priorities
        id = changes[type]
        if id
            changes.favorites.push id

    # if we dont have our 4 favorites, pick at random
    for box in boxes when changes.favorites.length < 4
        if box.id not in changes.favorites and box.isSelectable()
            changes.favorites.push box.id

    @updateAttributes changes, callback


# Public: send a message using this account SMTP config
#
# message - a raw message
# callback - a (err, info) callback with the following parameters
#            :err
#            :info the nodemailer's info
#
# Returns void
Account::sendMessage = (message, callback) ->
    return callback null, messageId: 66 if @isTest()
    options =
        port: @smtpPort
        host: @smtpServer
        secure: @smtpSSL
        ignoreTLS: not @smtpTLS
        tls: rejectUnauthorized: false
    if @smtpMethod? and @smtpMethod isnt 'NONE'
        options.authMethod = @smtpMethod
    if @smtpMethod isnt 'NONE'
        options.auth =
            user: @smtpLogin or @login
            pass: @smtpPassword or @password

    transport = nodemailer.createTransport options

    transport.sendMail message, callback


# Private: check smtp credentials
# used in createIfValid
# throws AccountConfigError
#
# Returns a if the credentials are corrects
Account::testSMTPConnection = (callback) ->
    return callback null if @isTest()

    reject = _.once callback

    options =
        port: @smtpPort
        host: @smtpServer
        secure: @smtpSSL
        ignoreTLS: not @smtpTLS
        tls: rejectUnauthorized: false
    if @smtpMethod? and @smtpMethod isnt 'NONE'
        options.authMethod = @smtpMethod

    connection = new SMTPConnection options

    if @smtpMethod isnt 'NONE'
        auth =
            user: @smtpLogin or @login
            pass: @smtpPassword or @password

    connection.once 'error', (err) ->
        log.warn "SMTP CONNECTION ERROR", err
        reject new AccountConfigError 'smtpServer'

    # in case of wrong port, the connection takes forever to emit error
    timeout = setTimeout ->
        reject new AccountConfigError 'smtpPort'
        connection.close()
    , 10000

    connection.connect (err) =>
        return reject new AccountConfigError 'smtpServer' if err
        clearTimeout timeout

        if @smtpMethod isnt 'NONE'
            connection.login auth, (err) ->
                if err then reject new AccountConfigError 'auth'
                else callback null
                connection.close()
        else
            callback null
            connection.close()
