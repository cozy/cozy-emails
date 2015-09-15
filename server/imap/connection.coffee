NodeImapConnection = require 'imap'
{MailParser} = require 'mailparser'
stream_to_buffer_array = require '../utils/stream_to_array'
async = require 'async'
log = require('../utils/logging')(prefix: 'imap:extensions')
mailutils = require '../utils/jwz_tools'
errors = require '../utils/errors'
{ImapImpossible, isFolderForbidden} = errors
{isFolderDuplicate, isFolderUndeletable} = errors
_ = require 'lodash'




# Monkey patches : to be merged upstream ?
# Malformed message #1
# PROBLEM : missing semi colon in headers
# FOUND AT : aenario's rmf/All#525
# SENT FROM : some php script (probably very specific)
# @TODO : PR to mailparser to be more lenient in parsing headers ?
_old1 = MailParser::_parseHeaderLineWithParams
MailParser::_parseHeaderLineWithParams = (value) ->
    _old1.call this, value.replace '" format=flowed', '"; format=flowed'

#Public: node-imap ImapConnection with a few enhancements
module.exports = class ImapConnection extends NodeImapConnection

    # Public: get mailboxes flattened as an arry
    #
    # Returns (callback) {Array} of node-imap mailbox {Object}
    getBoxesArray: (callback) ->
        log.debug "getBoxesArray"
        @getBoxes (err, boxes) ->
            return callback err if err
            callback null, mailutils.flattenMailboxTree boxes

    # Public: node-imap addBox with special error handling
    #
    # Returns (callback) at completion
    addBox2: (name, callback) ->
        @addBox name, (err) ->
            if err and isFolderForbidden err
                callback new ImapImpossible 'folder forbidden', err

            else if err and isFolderDuplicate err
                callback new ImapImpossible 'folder duplicate', err

            else callback err

    # Public: node-imap renameBox with special error handling
    #
    # Returns (callback) at completion
    renameBox2: (oldname, newname, callback) ->
        @renameBox oldname, newname, (err) ->
            if err and isFolderForbidden err
                callback new ImapImpossible 'folder forbidden', err

            else if err and isFolderDuplicate err
                callback new ImapImpossible 'folder duplicate', err

            else callback err

    # Public: node-imap delBox with special error handling
    #
    # Returns (callback) at completion
    delBox2: (name, callback) ->
        @delBox name, (err) ->
            if err and isFolderUndeletable err
                callback new ImapImpossible 'folder undeletable', err

            else callback err

    # Public: fetch all message-id in the currently open mailbox
    #
    # Returns (callback) an {Object} with uid as keys and Message-id as values
    fetchBoxMessageIDs: (callback) ->
        log.debug "imap#fetchBoxMessageIDs"
        results = {}
        @search [['ALL']], (err, uids) =>
            log.debug "imap#fetchBoxMessageIDs#result", uids.length
            return callback err if err
            return callback null, [] if uids.length is 0

            fetch = @fetch uids, bodies: 'HEADER.FIELDS (MESSAGE-ID)'
            fetch.on 'error', (err) -> callback err
            fetch.on 'message', (msg) ->
                uid = null
                messageID = null
                msg.on 'error', (err) -> results.error = err
                msg.on 'attributes', (attrs) -> uid = attrs.uid
                msg.on 'end', -> results[uid] = messageID
                msg.on 'body', (stream) ->
                    stream_to_buffer_array stream, (err, parts) ->
                        return log.error "fetchBoxMessageIDs fail", err if err
                        buffer = Buffer.concat(parts)
                        header = buffer.toString('utf8').trim()
                        messageID = header.substring header.indexOf ':'

            fetch.on 'end', ->
                callback null, results


    # Public: fetch all messages UID in open box
    #
    # Returns (callback) an {Array} of UIDs
    fetchBoxMessageUIDs: (callback) ->
        log.debug "imap#fetchBoxMessageUIDs"
        @search [['ALL']], (err, uids) ->
            log.debug "imap#fetchBoxMessageUIDs#result", uids.length
            return callback err if err
            return callback null, uids

    # Public: fetch all message-ids and flags in open box since a given modseqno
    #
    # modseqno - {String} fetch changes after this number
    #
    # Returns (callback) an {Object} with uids as keys and
    #                    [mid, flags] as values of UIDs
    fetchMetadataSince: (modseqno, callback) ->
        log.debug "imap#fetchBoxMessageSince", modseqno
        @search [['MODSEQ', modseqno]], (err, uids) ->
            log.debug "imap#fetchBoxMessageSince#result", uids
            return callback err if err
            return callback null, {} unless uids.length
            results = {}
            fetch = @fetch uids, bodies: 'HEADER.FIELDS (MESSAGE-ID)'
            fetch.on 'error', callback
            fetch.on 'message', (msg) ->
                uid = null # message uid
                flags = null # message flags
                mid = null # message id
                msg.on 'error', (err) -> results.error = err
                msg.on 'end', -> results[uid] = [mid, flags]
                msg.on 'attributes', (attrs) ->
                    {flags, uid} = attrs
                msg.on 'body', (stream) ->
                    stream_to_buffer_array stream, (err, parts) ->
                        return callback err if err
                        header = Buffer.concat(parts).toString('utf8').trim()
                        mid = header.substring header.indexOf(':') + 1

            fetch.on 'end', -> callback null, results

    # Public: fetch all message-ids and flags in open box
    #
    # min - {Number} fetch uid above this number
    # max - {Number} fetch uid below this number
    #
    # Returns (callback) an {Object} with uids as keys and
    #                    [mid, flags] as values of UIDs
    fetchMetadata: (min, max, callback) ->
        log.debug "imap#fetchMetadata", min, max

        @search [['UID', "#{min}:#{max}"]], (err, uids) ->
            log.debug "imap#fetchMetadata#results", err, uids?.length
            return callback err if err
            return callback null, {} unless uids.length
            results = {}
            fetch = @fetch uids, bodies: 'HEADER.FIELDS (MESSAGE-ID)'
            fetch.on 'error', callback
            fetch.on 'message', (msg) ->
                uid = null # message uid
                flags = null # message flags
                mid = null # message id
                msg.on 'error', (err) -> results.error = err
                msg.on 'end', -> results[uid] = [mid, flags]
                msg.on 'attributes', (attrs) ->
                    {flags, uid} = attrs
                msg.on 'body', (stream) ->
                    stream_to_buffer_array stream, (err, parts) ->
                        return callback err if err
                        header = Buffer.concat(parts).toString('utf8').trim()
                        mid = header.substring header.indexOf(':') + 1

            fetch.on 'end', -> callback null, results

    # Public: fetch one mail by its UID from the open box
    #
    # uid - {Number} the uid to fetch
    #
    # Returns (callback) an {Object} with uids as keys and
    #                    [mid, flags] as values of UIDs
    fetchOneMail: (uid, callback) ->

        messageReceived = false
        fetch = @fetch [uid], size: true, bodies: ''
        fetch.on 'message', (msg) ->
            flags = []
            messageReceived = true
            msg.once 'error', callback
            msg.on 'attributes', (attrs) ->
                flags = attrs.flags
                # for now, we dont use the msg attributes

            msg.on 'body', (stream) ->
                # this should be streaming
                # but node-imap#345
                stream_to_buffer_array stream, (err, buffers) ->
                    return callback err if err
                    mailparser = new MailParser()
                    mailparser.on 'error', callback
                    mailparser.on 'end', (mail) ->
                        mail.flags = flags
                        callback null, mail
                    mailparser.write part for part in buffers
                    mailparser.end()

        fetch.on 'error', callback
        fetch.on 'end', ->
            unless messageReceived
                callback new Error 'fetch ended with no message'

    # Public: fetch one raw mail by its UID from the open box
    #
    # uid - {Number} the uid to fetch
    #
    # Returns (callback) the {Buffer} containing the RFC822 message
    fetchOneMailRaw: (uid, callback) ->

        messageReceived = false
        fetch = @fetch [uid], size: true, bodies: ''
        fetch.on 'message', (msg) ->
            flags = []
            messageReceived = true
            msg.once 'error', callback
            msg.on 'attributes', (attrs) ->
                flags = attrs.flags
                # for now, we dont use the msg attributes

            msg.on 'body', (stream, info) ->
                stream_to_buffer_array stream, (err, parts) ->
                    return callback err if err
                    callback null, Buffer.concat(parts)

        fetch.on 'error', callback
        fetch.on 'end', ->
            unless messageReceived
                callback new Error 'fetch ended with no message'

    # Public: copy one message by its UID from the open box to several other
    # mailboxes
    #
    # uid - {Number} the uid to fetch
    # paths - {Array} of {String} the mailboxes where to copy this message
    #
    # Returns (callback) at completion
    multicopy: (uid, paths, callback) ->
        async.mapSeries paths, (path, cb) =>
            @copy uid, path, cb
        , callback

    # Public: remove one message from several mailboxes
    #
    # paths - {Array} of {Object}(path, uid) the messages to remove
    #
    # Returns (callback) at completion
    multiremove: (paths, callback) ->
        async.eachSeries paths, ({path, uid}, cb) =>
            return cb new Error 'no message to remove' unless uid?
            @deleteMessageInBox path, uid, cb
        , callback


    deleteAndExpunge: (uid, callback) ->
        @addFlags uid, '\\Deleted', (err) ->
            return callback err if err
            @expunge uid, callback

    multimove: (uids, dests, callback) ->
        if uids.length is 0
            callback null
        else
            [first, rest...] = dests
            @multicopy uids, rest, (err) =>
                return callback err if err
                @move uids, first, callback

    multiexpunge: (uids, callback) ->
        if uids.length is 0
            callback null
        else
            @deleteAndExpunge uids, callback

    # Public: remove one message from a box
    # open box, mark \\Deleted and expunge.
    #
    # path - {String} the mailbox to remove from
    # uid - {Number} the message to remove
    #
    # Returns (callback) at completion
    deleteMessageInBox: (path, uid, callback) ->
        async.series [
            (cb) => @openBox path, cb
            (cb) => @addFlags uid, '\\Deleted', cb
            (cb) => @expunge uid, cb
        ], callback

module.exports = ImapConnection
