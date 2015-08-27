Process = require './_base'
async = require 'async'
Message = require '../models/message'
_ = require 'lodash'
log = require('../utils/logging')(prefix: 'process:box_refresh_fast')

# This process refreshes mails in this box using rfc4551. This is similar to
# {MailboxRefreshDeep} but faster if the server supports RFC4551.
#
# First, we ask the server for all updated messages since last
# refresh. {Mailbox::_refreshGetImapStatus}
#
# Then we apply these changes in {Mailbox::_refreshCreatedAndUpdated}
#
# Because RFC4551 doesnt give a way for the server to indicate expunged
# messages, at this point, we have all new and updated messages, but we
# may still have messages in cozy that were expungeds in IMAP.
# We refresh deletion if needed in {MailboxRefreshFast::refreshDeleted}
#
# Finally we store the new highestmodseq, so we can ask for changes
# since this refresh. We also store the IMAP number of message because
# it can be different from the cozy one due to twin messages.
#
# This process doesn't use the safeloop, because we want to break if something
# goes wrong, so as to not checkpoint untreated highestmodseq
#
# options
#  :limitbybox
#  :firstImport
#  :storeHighestModSeq
#  :mailbox
#
# actions on couchdb
#   - create / delete / update messages to match the IMAP state of this box
#   - set lastSync and optionally total and higestmod on the box
#
# output
#  :shouldNotif - whether or not the unread count has changed in this refresh
#
module.exports = class MailboxRefreshFast extends Process

    code: 'mailbox-refresh-fast'
    @algorithmFailure = {Symbol: 'fastFailure'}


    initialize: (options, callback) ->

        @shouldNotif = false
        @nbAdded = 0
        @mailbox = options.mailbox
        @lastHighestModSeq = @mailbox.lastHighestModSeq
        @lastTotal = @mailbox.lastTotal or 0
        @changes = {}
        @changedUids = []

        async.series [
            @fetchChanges
            @fetchCozyMessagesForChanges
            @refreshCreatedAndUpdated
            @checkNeedDeletion
            @refreshDeletion
        ], callback

    fetchChanges: (next) =>
        log.debug "fetchChanges"
        @mailbox.doLaterWithBox (imap, imapbox, releaseImap) =>
            @newHighestModSeq = imapbox.highestmodseq
            @newImapTotal = imapbox.messages.total
            if @newHighestModSeq is @lastHighestModSeq
                releaseImap()
            else
                imap.fetchMetadataSince @lastHighestModSeq, (err, changes) =>
                    return next err if err
                    @changes = changes
                    @changedUids = Object.keys changes
                    releaseImap err
        , next

    fetchCozyMessagesForChanges: (callback) =>
        return callback null unless @changedUids.length
        log.debug "fetchCozyMessagesForChanges"

        keys = @changedUids.map (uid) =>
            ['uid', @mailbox.id, parseInt(uid)]

        Message.rawRequest 'byMailboxRequest',
            reduce: false
            keys: keys
            include_docs: true
        , (err, rows) =>
            @cozyMessages = {}
            return callback err if err
            for row in rows
                uid = row.key[2]
                @cozyMessages[uid] = new Message(row.doc)
            callback null

    # Private: Apply creation & updates from IMAP to the cozy
    #
    # changes - the {Object} from {::_refreshGetImapStatus}
    #
    # Returns (callback) at completion
    refreshCreatedAndUpdated: (callback) =>
        log.debug "refreshCreatedAndUpdated"
        async.eachSeries @changedUids, (uid, next) =>
            [mid, flags] = @changes[uid]
            uid = parseInt uid
            message = @cozyMessages[uid]
            if message and not _.xor(message.flags, flags).length
                setImmediate next
            else if message
                @noChange = false
                message.updateAttributes {flags}, next
            else
                Message.fetchOrUpdate @mailbox, {mid, uid}, (err, info) =>
                    @shouldNotif or= info.shouldNotif
                    @nbAdded += 1 if info?.actuallyAdded
                    next err
        , callback

    # Private: Apply deletions from IMAP to the cozy
    #
    # imapTotal - {Number} total number of messages in the IMAP box
    # nbAdded   - {Number} number of messages added
    #
    # Returns (callback) at completion
    checkNeedDeletion: (callback) =>

        log.debug """
            refreshDeleted L=#{@lastTotal} A=#{@nbAdded} I=#{@newImapTotal}"""

        # if the last message count + number of messages added is equal
        # to the current count, no message have been deleted
        if @lastTotal + @nbAdded is @newImapTotal
            @needDeletion = false
            callback null

        # else if it is inferior, it means our algo broke somewhere
        # throw an error, and let {::imap_refresh} do a deep refresh
        else if @lastTotal + @nbAdded < @newImapTotal
            log.warn """
              #{@lastTotal} + #{@nbAdded} < #{@newImapTotal} on #{@mailbox.path}
            """
            callback MailboxRefreshFast.algorithmFailure

        # else if it is superior, this means some messages has been deleted
        # in imap. We delete them in cozy too.
        else
            @needDeletion = true
            callback null

    fetchCozyUIDs: (callback) =>
        Message.rawRequest 'byMailboxRequest',
            startkey: ['uid', @mailbox.id]
            endkey: ['uid', @mailbox.id, {}]
            reduce: true
            group_level: 3
         , (err, rows) =>
            return callback err if err
            @cozyUIDs = (row.key[2] for row in rows)
            callback null

    fetchImapUIDs: (callback) =>
        @mailbox.doLaterWithBox (imap, imapbox, cb) ->
            imap.fetchBoxMessageUIDs cb
        , (err, imapUIDs) =>
            return callback err if err
            @imapUIDs = imapUIDs
            callback null

    #@TODO : merge me with fetchCozyMessagesForChanges
    fetchCozyMessagesForDeletion: (callback) ->
        keys = @deletedUIDs.map (uid) =>
            ['uid', @mailbox.id, uid]

        Message.rawRequest 'byMailboxRequest',
            reduce: false
            keys: keys
            include_docs: true
        , (err, rows) =>
            return callback err if err
            @deletedMessages = rows.map (row) -> new Message row.doc
            log.debug "refreshDeleted#toDeleteMsgs", @deletedMessages.length
            callback null

    refreshDeletion: (callback) =>
        return callback null unless @needDeletion

        async.series [
            (cb) => @fetchCozyUIDs cb

            (cb) => @fetchImapUIDs cb

            (cb) =>
                log.debug "refreshDeleted#uids", @cozyUIDs.length,
                                                            @imapUIDs.length

                @deletedUIDs = []
                for uid in @cozyUIDs when uid not in @imapUIDs
                    @deletedUIDs.push uid

                @fetchCozyMessagesForDeletion cb

            (cb) =>
                async.eachSeries @deletedMessages, (message, next) =>
                    message.removeFromMailbox @mailbox, false, next
                , cb

        ], callback


    storeLastSync: (callback) ->
        if @newImapTotal isnt @mailbox.lastTotal or
           @newHighestModSeq isnt @mailbox.lastHighestModSeq

            @mailbox.updateAttributes
                lastHighestModSeq: @newHighestModSeq
                lastTotal: @newImapTotal
                lastSync: new Date().toISOString()
            , callback


