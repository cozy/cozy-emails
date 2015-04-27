cozydb = require 'cozydb'

# Public: the account model
class Account extends cozydb.CozyModel
    @docType: 'Account'

    # Public: allowed fields for an account
    @schema:
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
        imapLogin: String           # IMAP login
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
        patchIgnored: Boolean       # has patchIgnored been applied ?
        signature: String            # Signature to add at the end of messages

    # Public: find an account by id
    # cozydb's find can return no error and no account (if id isnt an account)
    # this version always return one or the other
    #  id - id of the account to find
    #  callback - Function(Error err, Account account)
    @findSafe: (id, callback) ->
        Account.find id, (err, account) ->
            return callback err if err
            return callback new NotFound "Account##{id}" unless account
            callback null, account

    # Public: Refresh all accounts
    #
    # limitByBox - {Number} sync only limitByBox latest messages from
    #                   each box
    # onlyFavorites - {Boolean} sync only favorite boxes
    #
    # Returns (callback) at task completion
    @refreshAllAccounts: (limitByBox, onlyFavorites, callback) ->
        Account.request 'all', (err, accounts) ->
            return callback err if err
            options =
                accounts: accounts
                limitByBox: limitByBox
                onlyFavorites: onlyFavorites
                firstImport: false
            Account.refreshAccounts options, callback

    # Public: remove all orphans message & mailboxes then refresh all accounts
    #
    # limitByBox - {Number} sync only limitByBox latest messages from
    #                   each box
    # onlyFavorites - {Boolean} sync only favorite boxes
    #
    # Returns (callback) at task completion
    @removeOrphansAndRefresh: (limitByBox, onlyFavorites, callback) ->

        allAccounts = []
        existingAccountIDs = []
        existingMailboxIDs = []
        toIgnore = []

        async.series [
            (cb) -> # first fetch all accounts
                Account.all (err, accounts) ->
                    return cb err if err
                    existingAccountIDs = accounts.map (account) -> account.id
                    allAccounts = accounts
                    cb null

            (cb) ->
                # then remove all mailbox associated with a deleted account
                Mailbox.removeOrphans existingAccountIDs, (err, existingIDs) ->
                    return cb err if err
                    existingMailboxIDs = existingIDs
                    cb null

            (cb) ->
                # then remove all messages associated with a deleted box
                Message.removeOrphans existingMailboxIDs, cb

            (cb) ->
                # then apply the ignored patch to all accounts
                async.eachSeries allAccounts, (account, cbLoop) ->
                    account.applyPatchIgnored (err) ->
                        log.error err if err
                        cbLoop null # loop anyway
                , cb


        ], (err) ->
            return callback err if err
            options =
                accounts: allAccounts
                limitByBox: limitByBox
                onlyFavorites: onlyFavorites
                firstImport: false
                periodic: CONSTANTS.REFRESH_INTERVAL
            Account.refreshAccounts options, callback




    # Public: refresh a list of accounts
    #
    # options - the refresh parameters
    #       :accounts - {Array}[{Account}] accounts to sync
    #       :limitByBox - {Number} sync only limitByBox latest messages from
    #                   each box
    #       :onlyFavorites - {Boolean} sync only favorite boxes
    #       :periodic - {Number} fire another refresh periodic ms after this
    #                  one is finished
    #
    # Returns (callback) at task completion
    @refreshAccounts: (options, callback) ->
        {accounts, limitByBox, onlyFavorites, firstImport, periodic} = options
        errors = {}
        async.eachSeries accounts, (account, cb) ->
            log.debug "refreshing account #{account.label}"
            return cb null if account.isTest()
            return cb null if account.isRefreshing()
            accountOptions = {limitByBox, onlyFavorites, firstImport}
            account.imap_fetchMails accountOptions, (err) ->
                log.debug "done refreshing account #{account.label}"
                if err
                    log.error "CANT REFRESH ACCOUNT", account.label, err
                    errors[account.id] = err
                # refresh all accounts even if one fails
                cb null
        , ->
            if periodic?
                clearTimeout refreshTimeout
                refreshTimeout = setTimeout ->
                    log.debug "doing periodic refresh"
                    # periodic refresh should only check new messages on
                    # favorites mailboxes
                    options.onlyFavorites = true
                    options.limitByBox    = CONSTANTS.LIMIT_BY_BOX
                    Account.refreshAccounts options
                , periodic
            if callback?
                if Object.keys(errors).length > 0
                    error = new RefreshError errors
                callback error


    # Public: fetch the mailbox tree of a new {Account}
    # if the fetch succeeds, create the account and mailboxes in couch
    # else throw an {AccountConfigError}
    # returns fast once the account and mailboxes has been created
    # in the background, proceeds to download mails
    #
    # data - account parameters
    #
    # Returns (callback) {Account} the created account
    @createIfValid: (data, callback) ->

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


    # Public: get all accounts formatted by {::toClientObject}
    #
    # Returns  {Object} the client formated account
    @clientList: (callback) ->
        Account.request 'all', (err, accounts) ->
            return callback err if err
            async.map accounts, (account, cb) ->
                account.toClientObject cb
            , callback


    # Public: wrap an async function (the operation) to get a connection from
    # the pool before performing it and release the connection once it is done.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doASAP: (operation, callback) ->
        ImapPool.get(@id).doASAP operation, callback

    # Public: check if an account is test (created by fixtures)
    #
    # Returns {Boolean} if this account is a test account
    isTest: ->
        @accountType is 'TEST'

    # Public: check if the pool linked to this account is currently
    # refrershing.
    #
    # Returns {Boolean} if this account is a test account
    isRefreshing: ->
        ImapPool.get(@id).isRefreshing

    # Public: set the refreshing flag value on the pool linked to this
    # account.
    #
    # value - {Boolean} whether this account is currently refreshing
    #
    # Returns void
    setRefreshing: (value) ->
        ImapPool.get(@id).isRefreshing = value

    # Public: patch this account to mark its junk & spam message as ignored
    #
    #
    # Returns (callback) at completion
    applyPatchIgnored: (callback) ->
        log.debug "applyPatchIgnored, already = ", @patchIgnored
        return callback null if @patchIgnored

        boxes = []
        hadError = false
        boxes.push @trashMailbox if @trashMailbox
        boxes.push @junkMailbox if @junkMailbox
        log.debug "applyPatchIgnored", boxes
        async.eachSeries boxes, (boxID, cb) ->
            Mailbox.markAllMessagesAsIgnored boxID, (err) ->
                if err
                    hadError = true
                    log.error err
                cb null
        , (err) =>
            if hadError
                log.debug "applyPatchIgnored:fail", @id
                callback null
            else
                log.debug "applyPatchIgnored:success", @id
                # if there was no error, the account is patched
                # note it so we dont apply patch again
                changes = patchIgnored: true
                @updateAttributes changes, callback


    # Public: test an account connection
    # callback - {Boolean} whether this account is currently refreshing
    #
    # Throws {AccountConfigError}
    #
    # Returns (callback) void if no error
    testConnections: (callback) ->
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
    forgetBox: (boxid, callback) ->
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
    destroyEverything: (callback) ->
        async.series [
            (cb) => @destroy cb
            (cb) => Mailbox.destroyByAccount @id, cb
            (cb) => Message.safeDestroyByAccountID @id, cb
        ], callback

    # Public: get the account total unread message count
    #
    # Returns (callback) {Number} total unread message count
    totalUnread: (callback) ->
        Message.rawRequest 'totalUnreadByAccount',
            key: @id,
            reduce: true
        , (err, results) ->
            return callback err if err
            callback null, results?[0]?.value or 0

    # Public: get the account's mailboxes in cozy
    #
    # Returns (callback) {Array} of {Object}
    getMailboxes: (callback) ->
        Mailbox.rawRequest 'treeMap',
            startkey: [@id]
            endkey: [@id, {}]
            include_docs: true
        , callback

    # Public: return the account formatted
    # for usage by the client
    # (with mailboxes and counters)
    toClientObject: (callback) ->
        rawObject = @toObject()
        rawObject.favorites ?= []

        async.parallel
            totalUnread: (cb) => @totalUnread cb
            mailboxes:   (cb) => @getMailboxes cb
            counts:      (cb) -> Mailbox.getCounts null, cb

        , (err, {mailboxes, counts, totalUnread}) ->
            return callback err if err



            rawObject.totalUnread = totalUnread
            rawObject.mailboxes = mailboxes.map (row) ->
                box = row.doc
                id = box.id or row.id
                count = counts[id]
                return clientBox =
                    id       : id
                    label    : box.label
                    tree     : box.tree
                    attribs  : box.attribs
                    nbTotal  : count?.total  or 0
                    nbUnread : count?.unread or 0
                    nbRecent : count?.recent or 0
                    lastSync : box.lastSync

            callback null, rawObject

    # Public: get the account's mailboxes in imap
    #
    # Returns (callback) {Array} of nodeimap mailbox raw {Object}s
    imap_getBoxes: (callback) ->
        log.debug "getBoxes"
        @doASAP (imap, cb) ->
            imap.getBoxesArray cb
        , (err, boxes) ->
            return callback err, boxes or []

    # Public: refresh the account's mailboxes
    #
    # Returns (callback) {Array} of nodeimap mailbox raw {Object}s
    imap_refreshBoxes: (callback) ->
        log.debug "imap_refreshBoxes"
        account = this

        async.series [
            (cb) => Mailbox.getBoxes @id, cb
            (cb) => @imap_getBoxes cb
        ], (err, results) ->
            log.debug "refreshBoxes#results"
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

            log.debug "refreshBoxes#results2", boxToAdd.length,
                toFetch.length, toDestroy.length

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
    # options - the fetch params
    #       :limitByBox - the maximum {Number} of message to fetch at once
    #                      for each box
    #       :onlyFavorites - {Boolean} fetch messages only for favorite
    #                          mailboxes
    #       :firstImport - {Boolean} Is this the account first import
    #
    # Returns (callback) at task completion
    imap_fetchMails: (options, callback) ->
        {limitByBox, onlyFavorites, firstImport} = options
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

            log.info "FETCHING ACCOUNT #{account.label} : #{toFetch.length}"
            log.info "  BOXES  #{toDestroy.length} BOXES TO DESTROY"
            nb = toFetch.length + 1
            reporter = ImapReporter.accountFetch account, nb, firstImport
            shouldNotifAccount = false

            # fetch INBOX first
            toFetch.sort (a, b) ->
                return if a.label is 'INBOX' then -1
                else return 1

            async.eachSeries toFetch, (box, cb) ->
                boxOptions = {limitByBox, firstImport}
                box.imap_fetchMails boxOptions, (err, shouldNotif) ->
                    # @TODO : Figure out how to distinguish a mailbox that
                    # is not selectable but not marked as such. In the meantime
                    # dont pop the error to the client
                    if err and not isMailboxDontExist err
                        reporter.onError err
                    reporter.addProgress 1
                    shouldNotifAccount = true if shouldNotif
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
                    if shouldNotifAccount
                        notifications.accountRefreshed account
                    callback null

    # Public: fetch an account emails in two step
    # first 100 message in each of the favorites mailbox
    # then all messages
    #
    # Returns (callback) at task completion
    imap_fetchMailsTwoSteps: (callback) ->
        log.debug "account#imap_fetchMails2Steps"
        firstStep = onlyFavorites: true, firstImport: true, limitByBox: 100
        secondStep = onlyFavorites: false, firstImport: true, limitByBox: null
        @imap_fetchMails firstStep, (err) =>
            return callback err if err
            @imap_fetchMails secondStep, (err) ->
                return callback err if err
                callback null

    # Public: create a mail in the given box
    # used for drafts
    #
    # box - the {Mailbox} to create mail into
    # message - a {Message} to create
    #
    # Returns (callback) UID of the created mail
    imap_createMail: (box, message, callback) ->

        # compile the message to text
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

    # Public: set an account xxxMailbox attributes & favorites
    # from a list of mailbox
    #
    # boxes - an array of {Mailbox} to scan
    #
    # Returns (callback) the updated account
    imap_scanBoxesForSpecialUse: (boxes, callback) ->
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
    # message - a NodeMailer Message object
    #
    # Returns (callback) {Object} info, the nodemailer infos
    sendMessage: (message, callback) ->
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
    testSMTPConnection: (callback) ->
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
            reject new AccountConfigError 'smtpServer', err

        # in case of wrong port, the connection takes forever to emit error
        timeout = setTimeout ->
            reject new AccountConfigError 'smtpPort'
            connection.close()
        , 10000

        connection.connect (err) =>
            return reject new AccountConfigError 'smtpServer', err if err
            clearTimeout timeout

            if @smtpMethod isnt 'NONE'
                connection.login auth, (err) ->
                    if err then reject new AccountConfigError 'auth', err
                    else callback null
                    connection.close()
            else
                callback null
                connection.close()


module.exports = Account
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
notifications = require '../utils/notifications'
require('../utils/socket_handler').wrapModel Account, 'account'
{AccountConfigError, RefreshError, NotFound, isMailboxDontExist} = \
                                                    require '../utils/errors'

refreshTimeout = null


