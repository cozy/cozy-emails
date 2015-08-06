async = require 'async'

module.exports = (items, iterator, done) ->
    errors = []
    async.eachSeries items, (item, next) ->
        wasImmediate = true
        iterator item, (err) ->
            errors.push err if err
            # loop anyway
            if wasImmediate then setImmediate next
            else next null
        wasImmediate = false
    , (err) ->
        return done err if err # this should never happens
        done errors
