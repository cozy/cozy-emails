Contact = require '../models/contact'
async = require 'async'
log = require('../utils/logging')(prefix: 'controllers:activity')
{BadRequest, NotFound} = require '../utils/errors'


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
            # Browser errors sent contains `stack`, otherwise it's a
            # `console.error` message to parse
            if activity.data.error?.stack
                log.error activity.data
                log.error activity.data.error?.stack
            else
                log.error JSON.parse activity.data.error.msg
            res.send 'ok'
        when 'warn'
            log.warn activity.data.msg
            res.send 'ok'
        when 'info', 'log'
            log.info activity.data.msg
            res.send 'ok'
        when 'debug'
            log.debug activity.data.msg
            res.send 'ok'
        else
            res.status(400).send
                name: "Unknown activity data type",
                error: true
