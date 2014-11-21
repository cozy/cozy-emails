americano = require 'americano-cozy'
async = require 'async'
stream_to_buffer_array = require '../utils/stream_to_array'

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
        stream = @getFile 'picture', (err) ->
            log.error "Contact #{contact.id} getting picture", err if err?
        stream_to_buffer_array stream (err, parts) =>
            return callback err if err
            base64 = Buffer.concat(parts).toString('base64')
            avatar = "data:image/jpeg;base64," + base64
            @datapoints.push
                name: 'avatar'
                value: avatar
            callback null, this
    else
        callback null, this

# @TODO try Couchdb ?attachments=true
Contact.requestWithPictures = (name, options, callback) ->
    Contact.request name, options, (err, contacts) ->
        async.mapSeries contacts, (contact, cb)  ->
            contact.includePicture cb
        , callback

Contact.createNoDuplicate = (data, callback) ->
    key = data.address
    Contact.request 'byEmail',
        key: data.address

    , (err, existings) ->
        return callback err if err
        return callback null, existings if existings?.length > 1

        contact =
            fn: data.name
            datapoints: [
              name: "email", value: data.address
            ]

        Contact.create contact, (err, created) ->
            console.log "C", err, created
            return callback err if err
            Contact.request 'byEmail', key: key, callback