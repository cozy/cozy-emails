americano = require 'americano-cozy'
_ = require 'lodash'

module.exports = Settings = americano.getModel 'MailsSettings',
    messagesPerPage: Number
    refreshInterval: Number
    displayConversation: Boolean
    composeInHTML: Boolean
    messageDisplayHTML: Boolean
    messageDisplayImages: Boolean
    messageConfirmDelete: Boolean
    lang: String
    plugins: (x) -> x

defaultSettings =
    messagesPerPage: 25
    displayConversation: false
    composeInHTML: true
    messageDisplayHTML: true
    messageDisplayImages: false
    messageConfirmDelete: true
    lang: 'en'
    refreshInterval: 5
    plugins: null

Settings.getInstance = (callback) ->
    Settings.request 'all', (err, settings) ->
        return callback err if err
        settings = settings?[0]?.toObject()
        settings = _.extend {}, defaultSettings, settings
        callback null, settings