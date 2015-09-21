_ = require 'lodash'
uuid = require 'uuid'
Logger = require('../utils/logging')
log = Logger('imap:reporter')
{EventEmitter} = require('events')

module.exports = class Process

    constructor: (options) ->
        @errors = []
        @options = options
        @id = @code + uuid.v4()
        log.debug "constructor process #{@id}"

    initialize: ->
        throw new Error 'initialize should be overriden by process subclass'

    summary: ->
        {
            @id,
            @finished,
            done: @getProgress(),
            total: 1,
            @errors,
            @box,
            @account,
            @code,
            @objectID,
            @firstImport
        }

    clone: ->
        return new @constructor(@options)

    getProgress: ->
        0.5

    abort: (callback) ->
        @aborted = true

    addCallback: (callback) ->
        @callbacks ?= []
        @callbacks.push callback

    run: (callback) ->
        log.debug "run process #{@id}"
        @addCallback callback
        @initialize @options, (err, arg1, arg2, arg3, arg4) =>
            cb err, arg1, arg2, arg3, arg4 for cb in @callbacks

    onError: (err) ->
        @errors.push Logger.getLasts() + "\n" + err.stack
        log.error "reporter err", err.stack
