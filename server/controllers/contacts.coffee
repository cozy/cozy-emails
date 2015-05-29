Contact = require '../models/contact'

module.exports.list = (req, res, next) ->
    Contact.list (err, contacts) ->
        return next err if err
        res.send contacts

module.exports.picture = (req, res, next) ->
    id = req.params.contactID
    filename = 'picture'
    stream = Contact.getFile id, filename, (err) -> next err
    stream.pipefilter = (dsResponse) ->
        res.setHeader(header, value) for header, value of dsResponse.headers
    req.on 'close', -> stream.abort()
    res.on 'close', -> stream.abort()
    stream.pipe res
