_ = require 'underscore'
EventEmitter = require('events').EventEmitter
StoreUtils = require '../libs/StoreUtils'

# Defines private variables here
_emails = []

###
    Defines here the private action's callbacks
###
__actions__ =
    'TEST_ACTION': (value) ->
        _emails.push value

        @emit 'change'

###
    Defines here the public data accessor
###
module.exports = EmailStore = _.extend EventEmitter.prototype,

    getAll: -> return _emails


StoreUtils.bind EmailStore, __actions__
