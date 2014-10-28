Contact = require '../models/contact'
contacts = [
    {name: "Claude Lambda"   , address: "claude.lambda@free.fr"},
    {name: "Alex Lambda"     , address: "alex.lambda@free.fr"},
    {name: "Dominique Lambda", address: "dominique.lambda@free.fr"},
    {name: "Camille Guique"  , address: "camille@guique.net"},
    {name: "Alix Guique"     , address: "alix@guique.net"},
    {name: "Dany Guique"     , address: "dany@guique.net"},
    {name: "Gwen Guique"     , address: "gwen@guique.net"}
]
ContactActivity =
    search: (data, cb) ->
        if data.query?
            Contact.request 'byName', key: data.query, cb
        else
            Contact.request 'all', cb
    create: (data, cb) ->
        contact =
            fn: data.contact.name
            datapoints: [
              name: "email", value: data.contact.address
            ]
        Contact.create contact, cb
    delete: (data, cb) ->
        console.log 'Request delete of ' + data
        Contact.find data.id, (err, contact) ->
            if err? or not contact?
                cb err
            else
                console.log "Deleting " + contact.id
                console.log contact
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
                                    contacts.push {id: contact.id, name: contact.fn, address: address}

                            res.send 201, result: contacts
                        else
                            res.send 200
            else
                res.send 400, {name: "Unknown activity name", error: true}
        else
            res.send 400, {name: "Unknown activity data type", error: true}

