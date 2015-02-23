Contact = require '../models/contact'
async = require 'async'
log = require('../utils/logging')(prefix: 'controllers:activity')
{BadRequest, NotFound} = require '../utils/errors'


includePictures = (contacts, callback) ->
    async.eachSeries contacts, (contact, cb)  ->
        if contact._attachments?.picture
            stream = contact.getFile 'picture', (err) ->
                log.error err if err?
            bufs = []
            stream.on 'data', (d) -> bufs.push d
            stream.on 'end', ->
                buf = Buffer.concat bufs
                avatar = "data:image/jpeg;base64," +
                    buf.toString('base64')
                contact.datapoints.push
                    name: 'avatar'
                    value: avatar
                cb null, contact
        else
            cb null, contact

    , callback

ContactActivity =
    search: (data, callback) ->

        if data.query?
            request = 'mailByName'
            params =
                startkey: data.query
                endkey:   data.query + "\uFFFF"
        else
            request = 'all'
            params = {}

        Contact.requestWithPictures request, params, callback


    create: (data, callback) ->
        if data.contact?.address?
            Contact.createNoDuplicate data.contact, callback
        else
            return callback new BadRequest 'BAD FORMAT'

    delete: (data, callback) ->
        Contact.find data.id, (err, contact) ->
            return callback err if err
            return callback new NotFound "CONTACT #{data.id}" unless contact
            contact.destroy callback

module.exports.create = (req, res, next) ->
    activity = req.body
    switch activity.data.type
        when 'contact'
            if ContactActivity[activity.name]?
                ContactActivity[activity.name] activity.data, (err, result) ->
                    if err?
                        res.status(400).send {name: err.message, error: true}
                    else
                        res.send result: result
            else
                res.status(400).send
                    name: "Unknown activity name",
                    error: true
        when 'error'
            log.error activity.data
            res.send null
        else
            res.status(400).send
                name: "Unknown activity data type",
                error: true

