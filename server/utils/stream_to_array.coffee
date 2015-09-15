stream = require 'stream'


module.exports = stream_to_buffer_array = (stream, cb) ->
    parts = []
    stream.on 'error', (err) -> cb err
    stream.on 'data', (d) -> parts.push d
    stream.on 'end', -> cb null, parts

module.exports.Bufferer = class Bufferer extends stream.Writable

    constructor: (onDone) ->
        super
        @chunks = []
        @onDone = onDone

    _write: (chunk, enc, next) =>
        @chunks.push(chunk)
        next()

    end: =>
        @onDone null, Buffer.concat @chunks
