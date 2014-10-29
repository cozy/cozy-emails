Promise = require 'bluebird'


# in this application, we do a lot of things one by one
# helper functions to do that
Promise::serie = (fn) ->
    @map fn, concurrency: 1

Promise.serie = (array, fn) ->
    Promise.map array, fn, concurrency: 1


#
# Mailbox.findPromised req.params.mailboxID
# .throwIfNull -> new HttpError 404, 'Mailbox not found'
#
Promise::throwIfNull = (errorMaker) ->
    @then (result) ->
        if result? then return result
        else throw errorMaker()