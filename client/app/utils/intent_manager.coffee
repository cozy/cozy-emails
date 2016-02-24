# Catch Talker.js top level var using the webpack `exports-loader`
Talker = require 'exports?Talker!../../vendor/talkerjs-1.0.1.js'

TIMEOUT = 3000 # 3 s


module.exports = class IntentManager


    constructor : ->
        @talker = new Talker window.parent, '*'


    send : (nameSpace, intent, timeout) ->
        @talker.timeout = if timeout then timeout else TIMEOUT
        @talker.send 'nameSpace', intent
