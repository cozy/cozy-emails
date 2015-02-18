Imap = require 'imap'
{MailParser} = require 'mailparser'
stream_to_buffer_array = require '../utils/stream_to_array'
async = require 'async'
log = require('../utils/logging')(prefix: 'imap:extensions')
mailutils = require '../utils/jwz_tools'
{ImapImpossible} = require '../utils/errors'
_ = require 'lodash'

# Error predicates
folderForbidden = (err) ->
    /Folder name (.*) is not allowed./.test err.message

folderDuplicate = (err) ->
    /Duplicate folder name/.test err.message

folderUndeletable = (err) ->
    /Internal folder cannot be deleted/.test err.message


# Monkey patches : to be merged upstream ?
# Malformed message #1
# PROBLEM : missing semi colon in headers
# FOUND AT : aenario's rmf/All#525
# SENT FROM : some php script (probably very specific)
# @TODO : PR to mailparser to be more lenient in parsing headers ?
_old1 = MailParser::_parseHeaderLineWithParams
MailParser::_parseHeaderLineWithParams = (value) ->
    _old1.call this, value.replace '" format=flowed', '"; format=flowed'


# fixes of node imap
# flatten the mailbox tree
Imap::getBoxesArray = (callback) ->
    log.debug "getBoxesArray"
    @getBoxes (err, boxes) ->
        return callback err if err
        callback null, mailutils.flattenMailboxTree boxes

# allow to call openBox on the same box with no effect
Imap::openBoxCheap = (name, callback) ->
    if @_box?.name is name
        callback null, @_box

    @openBox.apply @, arguments

# - typed error for user mistakes
Imap::addBox2 = (name, callback) ->
    @addBox name, (err) ->
        if err and folderForbidden err
            callback new ImapImpossible 'folder forbidden', err

        if err and folderDuplicate err
            callback new ImapImpossible 'folder duplicate', err

        callback err

Imap::renameBox2 = (oldname, newname, callback) ->
    @renameBox oldname, newname, (err) ->
        if err and folderForbidden err
            callback new ImapImpossible 'folder forbidden', err

        if err and folderDuplicate err
            callback new ImapImpossible 'folder duplicate', err

        callback err

Imap::delBox2 = (name, callback) ->
    @delBox name, (err) ->
        if err and folderUndeletable err
            callback new ImapImpossible 'folder undeletable', err

        callback err

# convenient functions for batch operations

# fetch all message-id in open box
# return An object {uid1:messageid1, uid2:messageid2} ...
Imap::fetchBoxMessageIDs = (callback) ->
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
                    return log.error err if err
                    buffer = Buffer.concat(parts)
                    header = buffer.toString('utf8').trim()
                    messageID = header.substring header.indexOf ':'

        fetch.on 'end', ->
            callback null, results


# fetch all message-uid in open box
# return An Array of UIDs
Imap::fetchBoxMessageUIDs = (callback) ->
    log.debug "imap#fetchBoxMessageUIDs"
    @search [['ALL']], (err, uids) ->
        log.debug "imap#fetchBoxMessageUIDs#result", uids
        return callback err if err
        return callback null, uids

# fetch metadata for a range of uid in open mailbox
# callback err, Map uid1 -> [messageid, flags]
Imap::fetchMetadata = (min, max, callback) ->
    log.debug "imap#fetchMetadata", min, max

    @search [['UID', "#{min}:#{max}"]], (err, uids) ->
        log.debug "imap#fetchMetadata#results", err, uids?.length
        return callback err if err
        return callback null, {} unless uids.length
        uids.sort().reverse()
        results = {}
        fetch = @fetch uids, bodies: 'HEADER.FIELDS (MESSAGE-ID)'
        fetch.on 'error', callback
        fetch.on 'message', (msg) ->
            uid = null # message uid
            flags = null # message flags
            mid = null # message id
            msg.on 'error', (err) -> results.error = err
            msg.on 'end', -> results[uid] = [ mid, flags ]
            msg.on 'attributes', (attrs) ->
                {flags, uid} = attrs
            msg.on 'body', (stream) ->
                stream_to_buffer_array stream, (err, parts) ->
                    return callback err if err
                    header = Buffer.concat(parts).toString('utf8').trim()
                    mid = header.substring header.indexOf(':') + 1

        fetch.on 'end', -> callback null, results

# fetch one mail by its UID from the currently open mailbox
# return a promise for the mailparser result
Imap::fetchOneMail = (uid, callback) ->

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

# fetch one mail by its UID from the currently open mailbox
# return the raw message
Imap::fetchOneMailRaw = (uid, callback) ->

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

# copy one message to multiple boxes
Imap::multicopy = (uid, paths, callback) ->
    async.mapSeries paths, (path, cb) =>
        @copy uid, path, cb
    , callback

# remove message from multiple boxes
Imap::multiremove = (paths, callback) ->
    async.eachSeries paths, ({path, uid}, cb) =>
        @deleteMessageInBox path, uid, cb
    , callback

# Perform a full delete cycle (\\Deleted & expunge) on one messsage.
Imap::deleteMessageInBox = (path, uid, callback) ->
    async.series [
        (cb) => @openBox path, cb
        (cb) => @addFlags uid, '\\Deleted', cb
        (cb) => @expunge uid, cb
    ], callback

module.exports = Imap
