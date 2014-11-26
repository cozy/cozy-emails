
module.exports = stream_to_buffer_array = (stream, cb) ->
    parts = []
    stream.on 'error', (err) -> cb err
    stream.on 'data', (d) -> parts.push d
    stream.on 'end', -> cb null, parts