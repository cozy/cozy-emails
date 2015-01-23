americano = require MODEL_MODULE
async = require 'async'
stream_to_buffer_array = require '../utils/stream_to_array'
log = require('../utils/logging')(prefix: 'models:contact')

module.exports = Contact = americano.getModel 'Contact',
    id            : String
    fn            : String
    n             : String
    datapoints    : (x) -> x
    note          : String
    tags          : (x) -> x
    _attachments  : Object

Contact::includePicture = (callback) ->
    if @_attachments?.picture
        stream = @getFile 'picture', (err) =>
            log.error "Contact #{@id} getting picture", err if err?
        stream_to_buffer_array stream, (err, parts) =>
            return callback err if err
            base64 = Buffer.concat(parts).toString('base64')
            avatar = "data:image/jpeg;base64," + base64
            @datapoints ?= []
            @datapoints.push
                name: 'avatar'
                value: avatar
            callback null, this
    else
        callback null, this

# @TODO try Couchdb ?attachments=true
Contact.requestWithPictures = (name, options, callback) ->
    log.info "requestWithPictures"
    Contact.request name, options, (err, contacts) ->
        outids = []
        out = []
        if contacts?
            async.eachSeries contacts, (contact, cb)  ->
                return cb null if contact.id in outids
                contact.includePicture (err, contactWIthPicture) ->
                    return cb err if err
                    outids.push contact.id
                    out.push contactWIthPicture
                    cb null

            , (err) ->
                callback err, out
        else
            callback null, []

Contact.createNoDuplicate = (data, callback) ->
    log.info "createNoDuplicate"
    key = data.address
    Contact.request 'byEmail',
        key: data.address

    , (err, existings) ->
        return callback err if err
        return callback null, existings if existings?.length > 0

        contact =
            fn: data.name
            datapoints: [
              name: "email", value: data.address
            ]

        Contact.create contact, (err, created) ->
            return callback err if err
            Contact.request 'byEmail', key: key, callback
