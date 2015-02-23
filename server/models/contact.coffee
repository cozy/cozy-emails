cozydb = require 'cozydb'
async = require 'async'
stream_to_buffer_array = require '../utils/stream_to_array'
log = require('../utils/logging')(prefix: 'models:contact')
stream = require 'stream'

module.exports = Contact = cozydb.getModel 'Contact',
    id            : String
    fn            : String
    n             : String
    datapoints    : cozydb.NoSchema
    note          : String
    tags          : [String]
    _attachments  : Object

Contact::includePicture = (callback) ->
    unless @_attachments?.picture
        callback null, this
    else
        pictureStream = @getFile 'picture', (err) =>
            log.error "Contact #{@id} getting picture", err if err?

        chunks = []
        bufferer = new stream.Writable
        bufferer._write = (chunk, enc, next) ->
            chunks.push(chunk)
            next()
        bufferer.end = =>
            base64 = Buffer.concat(chunks).toString('base64')
            avatar = "data:image/jpeg;base64," + base64
            @datapoints ?= []
            @datapoints.push
                name: 'avatar'
                value: avatar
            callback null, this

        pictureStream.pipe bufferer

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
    Contact.request 'mailByEmail',
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
            Contact.request 'mailByEmail', key: key, callback
