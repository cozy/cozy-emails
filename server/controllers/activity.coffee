contacts = [
    {name: "Claude Lambda"   , address: "claude.lambda@free.fr"},
    {name: "Alex Lambda"     , address: "alex.lambda@free.fr"},
    {name: "Dominique Lambda", address: "dominique.lambda@free.fr"},
    {name: "Camille Guique"  , address: "camille@guique.net"},
    {name: "Alix Guique"     , address: "alix@guique.net"},
    {name: "Dany Guique"     , address: "dany@guique.net"},
    {name: "Gwen Guique"     , address: "gwen@guique.net"}
]
Contact =
    search: (data) ->
        if data.query?
            re = new RegExp(data.query, 'gi')
            res = contacts.filter (contact) ->
                return re.test(contact.name + contact.address)
            return res
        else
            return contacts
    create: (data) ->
        contacts.push data.contact
        return null
module.exports.create = (req, res, next) ->
    activity = req.body
    switch activity.data.type
        when 'contact'
            if Contact[activity.name]?
                res.send 201, result: Contact[activity.name] activity.data
            else
                res.send 400, {name: "Unknown activity name", error: true}
        else
            res.send 400, {name: "Unknown activity data type", error: true}

