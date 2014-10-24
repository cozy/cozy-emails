Imap = require 'imap'
Promise = require 'bluebird'
{MailParser} = require 'mailparser'
{AccountConfigError} = require '../utils/errors'
_ = require 'lodash'
log = require('../utils/logging')(prefix: 'imap:promise')
stream_to_buffer_array = require '../utils/stream_to_array'


# Monkey patches : to be merged upstream ?
# Malformed message #1
# PROBLEM : missing semi colon in headers
# FOUND AT : aenario's rmf/All#525
# SENT FROM : some php script (probably very specific)
# @TODO : PR to mailparser to be more lenient in parsing headers ?
_old1 = MailParser::_parseHeaderLineWithParams
MailParser::_parseHeaderLineWithParams = (value) ->
    _old1.call this, value.replace '" format=flowed', '"; format=flowed'


# Error predicates
folderForbidden = (err) ->
    /Folder name (.*) is not allowed./.test err.message

folderDuplicate = (err) ->
    /Duplicate folder name/.test err.message

folderUndeletable = (err) ->
    /Internal folder cannot be deleted/.test err.message


Promise.promisifyAll Imap.prototype, suffix: 'Promised'
# Public: better Promisify of node-imap (due to event-based interface)
# one instance per connection
# instance is destroyed when connection is closed
module.exports = class ImapPromisified

    # called when the connection breaks randomly
    # can be overwritten
    onTerminated: ->

    # see node-imap for options
    constructor: (options) ->

        logger = require('../utils/logging')(prefix: 'imap:raw')
        options.debug = logger.debug.bind logger

        @_super = new Imap options

        # wait connection as a promise
        @waitConnected = new Promise (resolve, reject) =>
            @_super.once 'ready', => resolve this
            @_super.once 'error', (err) => reject err
            @_super.connect()

        # we time out the connection at 10s
        # if the port is wrong, the failure is too damn long
        .timeout 10000, 'cant reach host'
        .catch (err) =>
            # if the know the type of error, clean it up for the user

            if err.textCode is 'AUTHENTICATIONFAILED'
                throw new AccountConfigError 'auth'

            if err.code is 'ENOTFOUND' and err.syscall is 'getaddrinfo'
                throw new AccountConfigError 'imapServer'

            if err instanceof Promise.TimeoutError
                @_super.end()
                throw new AccountConfigError 'imapPort'

            if err.source is 'timeout-auth'
                # @TODO : this can happen for other reason,
                # we need to retry before throwing
                throw new AccountConfigError 'imapTLS'

            # unknown err
            throw err

        # once connection is resolved
        .tap =>
            @_super.once 'error', (err) ->
                # an error happened while connection active
                # @TODO : how do we handle this ?
                log.error "ERROR ?", err
            @_super.once 'close', (err) =>
                # if we did not expect the ending
                @closed = 'closed'
                @onTerminated?(err) unless @waitEnding
            @_super.once 'end', (err) =>
                # if we did not expect the ending
                @state = 'closed'
                @onTerminated?(err) unless @waitEnding

    # end the connection
    # if hard == false, we attempt to logout
    # else we destroy the socket
    end: (hard) ->
        return Promise.resolve('closed') if @state is 'closed'
        return @waitEnding if @waitEnding

        # do not end the connection before it is started
        @waitEnding = @waitConnected

        # if connection failed, waitEnding is resolved
        .catch -> Promise.resolve('closed')

        # if connection succeeded, end it
        .then =>
            new Promise (resolve, reject) =>
                if hard
                    # nuke the socket
                    @_super.destroy()
                    return resolve 'closed'
                else
                    # do a logout before closing
                    @_super.end()

                @_super.once 'error', ->
                    resolve new Error 'fail to logout'
                @_super.once 'end', ->
                    resolve 'closed'
                @_super.once 'close', ->
                    resolve 'closed'

    # see imap.getBoxes
    # change: return a Promise for an array of boxes
    getBoxes: ->
        IGNORE_ATTRIBUTES = ['\\HasNoChildren', '\\HasChildren']
        @_super.getBoxesPromised.apply @_super, arguments
        .then (tree) ->
            boxes = []
            # recursively browse the imap box tree building pathStr and pathArr
            do handleLevel = (children = tree, pathStr = '', pathArr = []) ->
                for name, child of children
                    subPathStr = pathStr + name + child.delimiter
                    subPathArr = pathArr.concat name
                    handleLevel child.children, subPathStr, subPathArr
                    boxes.push
                        label: name
                        delimiter: child.delimiter
                        path: pathStr + name
                        tree: subPathArr
                        attribs: _.difference child.attribs, IGNORE_ATTRIBUTES

            return boxes

    # see imap.openBox
    # return a Promise of the box
    # change : it is fast to open the same box multiple time
    openBox: (name) ->
        if @_super._box?.name is name
            return Promise.resolve @_super._box
        @_super.openBoxPromised.apply @_super, arguments


    # simple promisify
    append    : ->
        @_super.appendPromised.apply @_super, arguments

    search    : ->
        @_super.searchPromised.apply @_super, arguments

    move      : ->
        @_super.movePromised.apply @_super, arguments

    expunge   : ->
        @_super.expungePromised.apply @_super, arguments

    copy      : ->
        @_super.copyPromised.apply @_super, arguments

    setFlags  : ->
        @_super.setFlagsPromised.apply @_super, arguments

    delFlags  : ->
        @_super.delFlagsPromised.apply @_super, arguments

    addFlags  : ->
        @_super.addFlagsPromised.apply @_super, arguments

    addBox    : ->
        @_super.addBoxPromised.apply @_super, arguments
        .catch folderForbidden, (err) ->
            throw new ImapImpossible 'folder forbidden', err

        .catch folderDuplicate, (err) ->
            throw new ImapImpossible 'folder duplicate', err

    delBox    : ->
        @_super.delBoxPromised.apply @_super, arguments
        .catch folderUndeletable, (err) ->
            throw new ImapImpossible 'folder undeletable', err

    renameBox : ->
        @_super.renameBoxPromised.apply @_super, arguments
        .catch folderForbidden, (err) ->
            throw new ImapImpossible 'folder forbidden', err

        .catch folderDuplicate, (err) ->
            throw new ImapImpossible 'folder duplicate', err

    # fetch all message-id in this box
    # return a Promise for an object {uid1:messageid1, uid2:messageid2} ...
    fetchBoxMessageIds : ->
        return new Promise (resolve, reject) =>
            results = {}

            @search [['ALL']]
            .then (ids) =>
                fetch = @_super.fetch ids, bodies: 'HEADER.FIELDS (MESSAGE-ID)'
                fetch.on 'error', reject
                fetch.on 'message', (msg) ->
                    uid = null
                    messageID = null
                    msg.on 'error', (err) -> result.error = err
                    msg.on 'attributes', (attrs) -> uid = attrs.uid
                    msg.on 'end', -> results[uid] = messageID
                    msg.on 'body', (stream) ->
                        stream_to_buffer_array stream, (err, parts) ->
                            return log.error err if err
                            header = Buffer.concat(parts).toString('utf8').trim()
                            messageID = header.substring header.indexOf ':'

                fetch.on 'end', -> resolve results

    # fetch metadata for a range of uid in open mailbox
    # return a Promise for an object
    # {uid1: [messageid, flags as a bitfield]}
    fetchMetadata : (ids, range) ->
        return {} unless ids.length
        return new Promise (resolve, reject) =>
            results = {}
            fetch = @_super.fetch ids, bodies: 'HEADER.FIELDS (MESSAGE-ID)'
            fetch.on 'error', reject
            fetch.on 'message', (msg) ->
                uid = null # message uid
                flags = null # message flags
                mid = null # message id
                msg.on 'error', (err) -> result.error = err
                msg.on 'end', -> results[uid] = [ mid, flags ]
                msg.on 'attributes', (attrs) ->
                    {flags, uid} = attrs
                msg.on 'body', (stream) ->
                    stream_to_buffer_array stream, (err, parts) ->
                        return log.error err if err
                        header = Buffer.concat(parts).toString('utf8').trim()
                        mid = header.substring header.indexOf(':') + 1

            fetch.on 'end', -> resolve results

    # fetch one mail by its UID from the currently open mailbox
    # return a promise for the mailparser result
    fetchOneMail: (id) ->
        return new Promise (resolve, reject) =>
            fetch = @_super.fetch [id], size: true, bodies: ''
            messageReceived = false
            flags = []
            fetch.on 'message', (msg) ->
                messageReceived = true
                msg.once 'error', reject
                msg.on 'attributes', (attrs) ->
                    flags = attrs.flags
                    # for now, we dont use the msg attributes

                msg.on 'body', (stream) ->
                    # this should be streaming
                    # but node-imap#345
                    stream_to_buffer_array stream, (err, buffers) ->
                        return reject err if err
                        mailparser = new MailParser()
                        mailparser.on 'error', reject
                        mailparser.on 'end', (mail) ->
                            mail.flags = flags
                            resolve mail
                        mailparser.write part for part in buffers
                        mailparser.end()

            fetch.on 'error', reject
            fetch.on 'end', ->
                unless messageReceived
                    reject new Error 'fetch ended with no message'
