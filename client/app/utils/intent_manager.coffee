# Catch Talker.js top level var using the webpack `exports-loader`
Talker = require 'exports?Talker!../../vendor/talkerjs-1.0.1.js'

LayoutActionCreator = require '../actions/layout_action_creator'


TIMEOUT = 3000 # 3 s


class IntentManager

    constructor : ->
        @talker = new Talker window.parent, '*'


    send : (nameSpace, intent, timeout) ->
        @talker.timeout = if timeout then timeout else TIMEOUT
        @talker.send 'nameSpace', intent


# Init Web Intents
module.exports.initIntent = ->
    window.intentManager = new IntentManager()
    window.intentManager.send 'nameSpace',
        type: 'ping'
        from: 'mails'
    .then (message) ->
        LayoutActionCreator.intentAvailability true
    , (error) ->
        LayoutActionCreator.intentAvailability false
