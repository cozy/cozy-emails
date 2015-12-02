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
        oauthProvider: String       # If authentication use OAuth (only value
                                    #                   allowed for now: GMAIL)
        oauthAccessToken: String    # AccessToken
        oauthRefreshToken: String   # RefreshToken (in order to get an
                                    #                             access_token)
        oauthTimeout: Number        # AccessToken timeout
        initialized: Boolean        # Is the account ready ?
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
        draftMailbox:   String      # \Draft Maibox id
        sentMailbox:    String      # \Sent Maibox id
        trashMailbox:   String      # \Trash Maibox id
        junkMailbox:    String      # \Junk Maibox id
        allMailbox:     String      # \All Maibox id
        favorites:      [String]    # [String] Maibox id of displayed boxes
        patchIgnored:   Boolean     # has patchIgnored been applied ?
        supportRFC4551: Boolean     # does the account support CONDSTORE ?
        signature:      String      # Signature to add at the end of messages

        _passwordStillEncrypted: Boolean


    constructor: (attributes) ->
        if attributes.accountType is 'TEST'
            return new TestAccount attributes
        else
            super


    refreshPassword: (callback) ->
        # two possibilities
        # 1. mail started too soon and we just need to fetch the account
        #    password
        # 2. mail actually started while the DS doesnt have the keys
        #    we can only give up
        Account.find @id, (err, fetched) ->
            return callback err if err

            if fetched._passwordStillEncrypted
                callback new PasswordEncryptedError fetched

            else
                @password = fetched.password
                @_passwordStillEncrypted = undefined
                callback null


    # Public: check if an account is test (created by fixtures)
    #
    # Returns {Boolean} if this account is a test account
    isTest: -> false


    # Public: test an account connection
    # callback - {Boolean} whether this account is currently refreshing
    #
    # Throws {AccountConfigError}
    #
    # Returns (callback) void if no error
    testConnections: (callback) ->
        @testSMTPConnection (err) =>
            return callback err if err
            pool = new ImapPool this
            pool.doASAP (imap, cbRelease) ->
                cbRelease null, 'OK'
            , (err) ->
                pool.destroy()
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
        for attribute in Object.keys Constants.RFC6154 when @[attribute] is boxid
            changes[attribute] = null

        if boxid in @favorites
            changes.favorites = _.without @favorites, boxid

        if Object.keys(changes).length
            @updateAttributes changes, callback
        else
            callback null

    getReferencedBoxes: ->
        out = []
        for attribute in Object.keys Constants.RFC6154 when @[attribute]
            out.push @[attribute]
        for boxid of @favorites
            out.push boxid

        return out


    # Public: get the account's mailboxes in imap
    # also update the account supportRFC4551 attribute if needed
    #
    # Returns (callback) {Array} of nodeimap mailbox raw {Object}s
    imap_getBoxes: (callback) ->
        log.debug "getBoxes"
        supportRFC4551 = null
        ramStore.getImapPool(@).doASAP (imap, cb) ->
            supportRFC4551 = imap.serverSupports 'CONDSTORE'
            imap.getBoxesArray cb
        , (err, boxes) =>
            return callback err, [] if err

            if supportRFC4551 isnt @supportRFC4551
                log.debug "UPDATING ACCOUNT #{@id} rfc4551=#{@supportRFC4551}"
                @updateAttributes {supportRFC4551}, (err) ->
                    log.warn "fail to update account #{err.stack}" if err
                    callback null, boxes or []
            else
                callback null, boxes or []

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

            ramStore.getImapPool(@).doASAP (imap, cb) ->
                imap.append buffer,
                    mailbox: box.path
                    flags: message.flags
                , cb

            , (err, uid) ->
                return callback err if err
                callback null, uid

    # Public: send a message using this account SMTP config
    #
    # message - a NodeMailer Message object
    #
    # Returns (callback) {Object} info, the nodemailer infos
    sendMessage: (message, callback) ->
        # In NodeMailer, inReplyTo header should be a string, so we only keep
        # the first message ID (if replying to more than one message, others
        # ID will be in references header)
        inReplyTo = message.inReplyTo
        message.inReplyTo = inReplyTo?.shift()
        options = makeSMTPConfig this

        transport = nodemailer.createTransport options

        transport.sendMail message, (err, info) ->
            # restore inReplyTo header
            message.inReplyTo = inReplyTo
            callback err, info


    # Private: check smtp credentials
    # used in controllers/account:create
    # throws AccountConfigError
    #
    # Returns a if the credentials are corrects
    testSMTPConnection: (callback) ->
        reject = _.once callback

        options = makeSMTPConfig this

        connection = new SMTPConnection options

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
                connection.login options.auth, (err) =>
                    if err
                        field = if @smtpLogin then 'smtpAuth' else 'auth'
                        reject new AccountConfigError field, err
                    else
                        callback null
                    connection.close()
            else
                callback null
                connection.close()


class TestAccount extends Account

    constructor: (attributes) ->
        attributes ?= {}
        Account.cast attributes, this
        @id ?= attributes._id if attributes._id

    isTest: ->
        true
    testSMTPConnection: (callback) ->
        callback null
    sendMessage: (message, callback) ->
        callback null, messageId: 66
    imap_getBoxes: (callback) ->
        # lets pretend nothing has changed
        callback null, ramStore.getMailboxesByAccount @id


module.exports = Account
require('./model-events').wrapModel Account
# There is a circular dependency between ImapProcess & Account
# node handle if we require after module.exports definition
Message     = require './message'
Compiler    = require 'nodemailer/src/compiler'
ImapPool = require '../imap/pool'
errors = require '../utils/errors'
{AccountConfigError, RefreshError, PasswordEncryptedError} = errors
{NotFound} = require '../utils/errors'
{makeSMTPConfig} = require '../imap/account2config'
nodemailer  = require 'nodemailer'
SMTPConnection = require 'smtp-connection'
log = require('../utils/logging')(prefix: 'models:account')
_ = require 'lodash'
async = require 'async'
Constants = require '../utils/constants'
ramStore = require './store_account_and_boxes'

schema = Object.keys(Account.schema)
Account.saveFields = _.without schema, '_passwordStillEncrypted'

refreshTimeout = null
