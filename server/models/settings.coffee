americano = require 'americano-cozy'
_ = require 'lodash'

Any = (x) -> x

module.exports = Settings = americano.getModel 'MailsSettings',
    messagesPerPage      : type : Number,  default : 25
    refreshInterval      : type : Number,  default : 5
    displayConversation  : type : Boolean, default : true
    displayPreview       : type : Boolean, default : true
    composeInHTML        : type : Boolean, default : true
    messageDisplayHTML   : type : Boolean, default : true
    messageDisplayImages : type : Boolean, default : false
    messageConfirmDelete : type : Boolean, default : true
    lang                 : type : String,  default : 'en'
    plugins              : type : Any,     default : null

Settings.getInstance = (callback) ->
    Settings.request 'all', (err, settings) ->
        return callback err if err
        if existing = settings?[0]
            callback null, existing
        else
            callback null, new Settings()

Settings.get = (callback) ->
    Settings.getInstance (err, instance) ->
        callback err, instance?.toObject()


Settings.set = (changes, callback) ->
    Settings.getInstance (err, instance) ->
        return callback err if err
        instance[key] = value for key, value of changes
        instance.save callback