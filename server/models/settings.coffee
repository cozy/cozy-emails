americano = require MODEL_MODULE
_ = require 'lodash'

Any = (x) -> x

module.exports = Settings = americano.getModel 'MailsSettings',
    # SETTINGS
    #messagesPerPage      : type : Number,  default : 25
    composeInHTML        : type : Boolean, default : true
    composeOnTop         : type : Boolean, default : false
    desktopNotifications : type : Boolean, default : false
    displayConversation  : type : Boolean, default : true
    displayPreview       : type : Boolean, default : true
    layoutStyle          : type : String,  default : 'vertical'
    listStyle            : type : String,  default : 'default'
    messageConfirmDelete : type : Boolean, default : true
    messageDisplayHTML   : type : Boolean, default : true
    messageDisplayImages : type : Boolean, default : false
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
