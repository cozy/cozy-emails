americano = require 'americano-cozy'
Promise = require 'bluebird'

module.exports = Settings = americano.getModel 'MailsSettings',
    messagesPerPage: Number
    refreshInterval: Number
    displayConversation: Boolean
    displayPreview: Boolean
    composeInHTML: Boolean
    messageDisplayHTML: Boolean
    messageDisplayImages: Boolean
    messageConfirmDelete: Boolean
    lang: String
    plugins: (x) -> x


Settings.getInstance = ->
    Settings.requestPromised 'all'
    .get 0
    .then (settings) ->
        defaultSettings = new Settings
            messagesPerPage: 25
            displayConversation: false
            displayPreview: true
            composeInHTML: true
            messageDisplayHTML: true
            messageDisplayImages: false
            messageConfirmDelete: true
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
