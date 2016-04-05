cozydb = require 'cozydb'
_ = require 'lodash'

Any = (x) -> x

module.exports = Settings = cozydb.getModel 'MailsSettings',
    # SETTINGS
    #messagesPerPage      : type : Number,  default : 25
    autosaveDraft        : type : Boolean, default : true
    composeInHTML        : type : Boolean, default : true
    composeOnTop         : type : Boolean, default : false
    desktopNotifications : type : Boolean, default : false
    displayPreview       : type : Boolean, default : true
    layoutStyle          : type : String,  default : 'column'
    listStyle            : type : String,  default : 'default'
    messageConfirmDelete : type : Boolean, default : false
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

Settings.getDefault = (callback) ->
    settings =
        autosaveDraft        : true
        composeInHTML        : true
        composeOnTop         : true
        desktopNotifications : true
        displayPreview       : true
        layoutStyle          : 'column'
        listStyle            : 'default'
        messageConfirmDelete : false
        messageDisplayHTML   : true
        messageDisplayImages : false
        plugins:
            gallery:
                name: "Gallery"
                active: true
            mailkeys:
                name: "Keyboard shortcuts"
                active: true
            mediumeditor:
                name: "Medium Editor"
                active: true
            minislate:
                name: "Slate editor"
                active: false
            sample:
                name: "Sample plugin"
                active: false
            vcard:
                name: "VCard"
                active: false

    callback null, settings

Settings.set = (changes, callback) ->
    Settings.getInstance (err, instance) ->
        return callback err if err
        instance.updateAttributes changes, callback
