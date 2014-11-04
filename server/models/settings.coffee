americano = require 'americano-cozy'
Promise = require 'bluebird'

module.exports = Settings = americano.getModel 'MailsSettings',
    messagesPerPage: Number
    displayConversation: Boolean
    composeInHTML: Boolean
    messageDisplayHTML: Boolean
    messageDisplayImages: Boolean
    lang: String
    plugins: (x) -> x


Settings.getInstance = ->
    Settings.requestPromised 'all'
    .get 0
    .then (settings) ->
        defaultSettings = new Settings
            messagesPerPage: 5
            displayConversation: false
            composeInHTML: true
            messageDisplayHTML: true
            messageDisplayImages: false
            lang: 'en'
            refreshInterval: 5
            plugins: null
        if not settings?
            return defaultSettings
        else
            # merge settings with default
            for own key, value of defaultSettings
                if not settings[key]?
                    settings[key] = value
            return settings

Promise.promisifyAll Settings, suffix: 'Promised'
Promise.promisifyAll Settings::, suffix: 'Promised'
