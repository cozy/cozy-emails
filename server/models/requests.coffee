# See documentation on https://github.com/frankrousseau/americano-cozy/#requests

americano = require 'americano'

module.exports =
    template:
        # shortcut for emit doc._id, doc
        all: americano.defaultRequests.all

        # create all the requests you want!
        customRequest:
            map: (doc) ->
                # map function
            reduce: (key, values, rereduce) ->
                # non mandatory reduce function