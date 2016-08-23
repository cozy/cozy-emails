cozydb = require 'cozydb'
safeLoop = require '../utils/safeloop'
Constants = require '../utils/constants'

# Public: the mailbox model
class Mailbox extends cozydb.CozyModel
    @docType: 'Mailbox'
    @schema:
        accountID: String        # Parent account
        label: String            # Human readable label
        path: String             # IMAP path
        lastSync: String         # Date.ISOString of last full box synchro
        tree: [String]           # Normalized path as Array
        delimiter: String        # delimiter between this box and its children
        uidvalidity: Number      # Imap UIDValidity
        attribs: [String]        # [String] Attributes of this folder
        lastHighestModSeq: String # Last highestmodseq successfully synced
        lastTotal: Number         # Last imap total number of messages in box

    # map of account's attributes -> RFC6154 special use box attributes
    @RFC6154: Constants.RFC6154

    # Public: is this box selectable (ie. can contains mail)
    #
    # Returns {Boolean} if its selectable
    isSelectable: ->
        '\\Noselect' not in (@attribs or [])


    # Public: get this box usage by special attributes
    #
    # Returns {String} the account attribute to set or null
    RFC6154use: ->
        return 'inboxMailbox' if @path is 'INBOX'

        for field, attribute of Mailbox.RFC6154
            if attribute in @attribs
                return field

    # Public: try to guess this box usage by its name
    #
    # Returns {String} the account attribute to set or null
    guessUse: ->
        path = @path.toLowerCase()
        if /inbox/i.test path
            return 'inboxMailbox'
        else if /sent/i.test path
            return 'sentMailbox'
        else if /draft/i.test path
            return 'draftMailbox'
        else if /flagged/i.test path
            return 'flaggedMailbox'
        else if /important/i.test path
            return 'flaggedMailbox'
        else if /trash/i.test path
            return 'trashMailbox'
        else if /delete/i.test path
            return 'trashMailbox'
        else if /spam/i.test path
            return 'junkMailbox'
        else if /junk/i.test path
            return 'junkMailbox'
        else if /all/i.test path
            return 'allMailbox'

    # Public: set an account xxxMailbox attributes & favorites
    # from a list of mailbox
    #
    # boxes - an array of {Mailbox} to scan
    #
    # Returns (callback) the updated account
    @scanBoxesForSpecialUse: (boxes) ->
        guessed = {}
        changes = {initialized: true}

        for box in boxes
            type = box.RFC6154use()
            if type
                log.debug 'found', type
                changes[type] = box.id

            # do not attempt fuzzy match if the server uses RFC6154
            else
                type = box.guessUse()
                if type
                    log.debug 'found', type, 'guess'
                    guessed[type] = box.id

        # keep all guesses
        changes[guessRole] ?= boxID for guessRole, boxID in guessed

        changes.favorites = Mailbox.pickFavorites boxes, changes

        return changes

    @pickFavorites: (boxes, changes) ->
        favorites = []

        # pick the default 4 favorites box
        priorities = [
            'inboxMailbox', 'allMailbox',
            'sentMailbox', 'draftMailbox'
        ]

        # see if we have some of the priorities box
        for type in priorities
            id = changes[type]
            if id
                favorites.push id

        # if we dont have our 4 favorites, pick at random
        for box in boxes when favorites.length < 4
            if box.id not in favorites and box.isSelectable()
                favorites.push box.id

        return favorites



    # Public: wrap an async function (the operation) to get a connection from
    # the pool before performing it and release the connection once it is done.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doASAP: (operation, callback) ->
        ramStore.getImapPool(@).doASAP operation, callback

    # Public: wrap an async function (the operation) to get a connection from
    # the pool and open the mailbox without error before performing it and
    # release the connection once it is done.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doASAPWithBox: (operation, callback) ->
        ramStore.getImapPool(@).doASAPWithBox @, operation, callback

    # Public: wrap an async function (the operation) to get a connection from
    # the pool and open the mailbox without error before performing it and
    # release the connection once it is done. The operation will be put at the
    # bottom of the queue.
    #
    # operation - a Function({ImapConnection} conn, callback)
    #
    # Returns (callback) the result of operation
    doLaterWithBox: (operation, callback) ->
        ramStore.getImapPool(@).doLaterWithBox @, operation, callback

    # Public: rename a box in IMAP and Cozy
    #
    # newLabel - {String} the box updated label
    # newPath - {String} the box updated path
    #
    # Returns (callback) at completion
    imapcozy_rename: (newLabel, newPath, callback) ->
        log.debug "imapcozy_rename", newLabel, newPath
        @doASAP (imap, cbRelease) =>
            imap.renameBox2 @path, newPath, cbRelease
        , (err) =>
            log.debug "imapcozy_rename err", err
            return callback err if err
            @renameWithChildren newLabel, newPath, (err) ->
                return callback err if err
                callback null

    # Public: delete a box in IMAP and Cozy
    #
    # Returns (callback) at completion
    imapcozy_delete: (callback) ->
        log.debug "imapcozy_delete"
        account = ramStore.getAccount(@accountID)
        async.series [
            (cb) =>
                log.debug "imap_delete"
                @doASAP (imap, cbRelease) =>
                    imap.delBox2 @path, cbRelease
                , cb

            (cb) =>
                log.debug "account.forget"
                account = ramStore.getAccount @accountID
                account.forgetBox @id, cb

            (cb) =>
                boxes = ramStore.getSelfAndChildrenOf this
                safeLoop boxes, (box, next) ->
                    box.destroy next
                , (errors) ->
                    cb errors[0]

        ], (err) ->
            # this will leave some of this box messages
            callback err


    # Public: rename a box and its children in cozy
    #
    # newPath - {String} the new path
    # newLabel - {String} the new label
    #
    # Returns (callback) {Array} of {Mailbox} updated boxes
    renameWithChildren: (newLabel, newPath, callback) ->
        log.debug "renameWithChildren", newLabel, newPath, @path
        depth = @tree.length - 1
        path = @path

        boxes = ramStore.getSelfAndChildrenOf this
        log.debug "imapcozy_rename#boxes", boxes.length, depth

        async.eachSeries boxes, (box, cb) ->
            log.debug "imapcozy_rename#box", box
            changes = {}
            changes.path = box.path.replace path, newPath
            changes.tree = (item for item in box.tree)
            changes.tree[depth] = newLabel
            if box.tree.length is depth + 1 # self
                changes.label = newLabel
            box.updateAttributes changes, cb
        , callback

    # Public: create a mail in IMAP if it doesnt exist yet
    # use for sent mail
    #
    # account - {Account} the account
    # message - {Message} the message
    #
    # Returns (callback) at task completion
    imap_createMailNoDuplicate: (account, message, callback) ->
        messageID = message.headers['message-id']
        @doLaterWithBox (imap, imapbox, cb) ->
            imap.search [['HEADER', 'MESSAGE-ID', messageID]], cb
        , (err, uids) =>
            return callback err if err
            return callback null, uids?[0] if uids?[0]
            account.imap_createMail @, message, callback

    # Public: remove a mail in the given box
    # used for drafts
    #
    # uid - {Number} the message to remove
    #
    # Returns (callback) at completion
    imap_removeMail: (uid, callback) ->
        @doASAPWithBox (imap, imapbox, cbRelease) ->
            async.series [
                (cb) -> imap.addFlags uid, '\\Deleted', cb
                (cb) -> imap.expunge uid, cb
                (cb) -> imap.closeBox cb
            ], cbRelease
        , callback

    # Public: BEWARE expunge (permanent delete) all mails from this box
    #
    # Returns (callback) at completion
    imap_expungeMails: (callback) ->
        @doASAPWithBox (imap, imapbox, cbRelease) ->
            imap.fetchBoxMessageUIDs (err, uids) ->
                return cbRelease err if err
                return cbRelease null if uids.length is 0
                async.series [
                    (cb) -> imap.addFlags uids, '\\Deleted', cb
                    (cb) -> imap.expunge uids, cb
                    (cb) -> imap.closeBox cb
                ], cbRelease
        , (err) =>
            return callback err if err
            removal = new MessagesRemovalByMailbox mailboxID: @id
            removal.run callback

    # Public: whether this box messages should be ignored
    # in the account's total (trash or junk)
    #
    # Returns {Boolean} true if this message should be ignored.
    ignoreInCount: ->
        return Mailbox.RFC6154.trashMailbox in @attribs or
               Mailbox.RFC6154.junkMailbox  in @attribs or
               @guessUse() in ['trashMailbox', 'junkMailbox']


class TestMailbox extends Mailbox
    imap_expungeMails: (callback) =>
        removal = new MessagesRemovalByMailbox
            mailboxID: @id

        removal.run callback

module.exports = Mailbox
require('./model-events').wrapModel Mailbox
ramStore = require './store_account_and_boxes'
log = require('../utils/logging')(prefix: 'models:mailbox')
async = require 'async'
MessagesRemovalByMailbox = require '../processes/message_remove_by_mailbox'
