americano = require 'americano-cozy'
Promise = require 'bluebird'

module.exports = Settings = americano.getModel 'MailsSettings',
    messagesPerPage: Number
    displayConversation: Boolean
    composeInHTML: Boolean
    messageDisplayHTML: Boolean
    messageDisplayImages: Boolean
    lang: String


Settings.getInstance = ->
    Settings.requestPromised 'all'
    .get 0
    .then (settings) ->
        return settings or new Settings
            messagesPerPage: 5
            displayConversation: false
            composeInHTML: true
            messageDisplayHTML: true
            messageDisplayImages: false
            lang: 'en'

Promise.promisifyAll Settings, suffix: 'Promised'
Promise.promisifyAll Settings::, suffix: 'Promised'
