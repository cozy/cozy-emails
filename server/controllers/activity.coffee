Contact = require '../models/contact'
ContactActivity =
    search: (data, cb) ->
        if data.query?
            params =
                startkey: data.query
                endkey:   data.query + "\uFFFF"
            Contact.request 'byName',  params, cb
        else
            Contact.request 'all', cb
    create: (data, cb) ->
        Contact.request 'byEmail', key: data.contact.address, (err, contacts) ->
            if err
                cb err, null
            else
                if contacts.length is 0
                    contact =
                        fn: data.contact.name
                        datapoints: [
                          name: "email", value: data.contact.address
                        ]
                    Contact.create contact, cb
                else
                    cb null, contacts[0]
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
                        if result?
                            contacts = []
                            for contact in result
                                address = null
                                for dp in contact.datapoints
                                    if dp.name is 'email'
                                        address = dp.value
                                if address?
                                    newContact =
                                        id: contact.id
                                        name: contact.fn
                                        address: address
                                    contacts.push newContact

                            res.send 201, result: result
                        else
                            res.send 200, result: result
            else
                res.send 400, {name: "Unknown activity name", error: true}
        else
            res.send 400, {name: "Unknown activity data type", error: true}

