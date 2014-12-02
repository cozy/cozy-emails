americano = require 'americano-cozy'
_ = require 'lodash'

Any = (x) -> x

module.exports = Settings = americano.getModel 'MailsSettings',
    messagesPerPage      : type : Number,  default : 25
    refreshInterval      : type : Number,  default : 5
    displayConversation  : type : Boolean, default : true
    displayPreview       : type : Boolean, default : true
    composeInHTML        : type : Boolean, default : true
    composeOnTop         : type : Boolean, default : false
    messageDisplayHTML   : type : Boolean, default : true
    messageDisplayImages : type : Boolean, default : false
    messageConfirmDelete : type : Boolean, default : true
    lang                 : type : String,  default : 'en'
    listStyle            : type : String,  default : 'default'
    plugins              : type : Any,     default : null

Settings.getInstance = (callback) ->
    Settings.request 'all', (err, settings) ->
        return callback err if err
        existing = settings?[0]
        if existing
            callback null, existing
        else
            Settings.create {}, callback

Settings.get = (callback) ->
    Settings.getInstance (err, instance) ->
        callback err, instance?.toObject()


Settings.set = (changes, callback) ->
    Settings.getInstance (err, instance) ->
        return callback err if err
        instance.updateAttributes changes, callback
