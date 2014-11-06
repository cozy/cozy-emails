Contact = require '../models/contact'
Promise = require 'bluebird'
ContactActivity =
    search: (data, cb) ->
        onData = (err, result) ->
            if err?
                cb err, result
            else
                pictures = []
                result.forEach (contact) ->
                    p = new Promise (resolve, reject) ->
                        if contact._attachments?.picture
                            stream = contact.getFile 'picture', (err) ->
                                if err?
                                    console.log err
                            bufs = []
                            stream.on 'data', (d) -> bufs.push d
                            stream.on 'end', ->
                                buf = Buffer.concat bufs
                                avatar = "data:image/jpeg;base64," +
                                    buf.toString('base64')
                                contact.datapoints.push
                                    name: 'avatar'
                                    value: avatar
                                resolve contact
                        else
                            resolve contact
                    pictures.push p
                Promise.all(pictures).then (res) ->
                    cb err, res

        if data.query?
            params =
                startkey: data.query
                endkey:   data.query + "\uFFFF"
            Contact.request 'byName',  params, onData
        else
            Contact.request 'all', onData
    create: (data, cb) ->
        if data.contact?.address?
            key = data.contact.address
            Contact.request 'byEmail', key: key, (err, contacts) ->
                if err
                    cb err, null
                else
                    if contacts.length is 0
                        contact =
                            fn: data.contact.name
                            datapoints: [
                              name: "email", value: data.contact.address
                            ]
                        Contact.create contact, (err, result) ->
                            if err?
                                cb err, result
                            else
                                Contact.request 'byEmail', key: key, cb
                    else
                        cb null, contacts
        else
            cb "BAD FORMAT", null
    delete: (data, cb) ->
        Contact.find data.id, (err, contact) ->
            if err? or not contact?
                cb err
            else
                contact.destroy cb

module.exports.create = (req, res, next) ->
    activity = req.body
    switch activity.data.type
        when 'contact'
            if ContactActivity[activity.name]?
                ContactActivity[activity.name] activity.data, (err, result) ->
                    if err?
                        res.send 400, {name: err, error: true}
                    else
                        res.send 200, result: result
            else
                res.send 400, {name: "Unknown activity name", error: true}
        else
            res.send 400, {name: "Unknown activity data type", error: true}

