americano = require 'americano-cozy'

module.exports = CozyInstance = americano.getModel 'CozyInstance',
    id:     type: String
    domain: type: String
    locale: type: String

CozyInstance.first = (callback) ->
    CozyInstance.request 'all', (err, instances) ->
        if err then callback err
        else if not instances or instances.length is 0 then callback null, null
        else  callback null, instances[0]

CozyInstance.getURL = (callback) ->
    CozyInstance.first (err, instance) ->
        if err then callback err
        else if instance?.domain
            url = instance.domain
            .replace('http://', '')
            .replace('https://', '')
            callback null, "https://#{url}/"
        else
            callback new Error 'No instance domain set'

CozyInstance.getLocale = (callback) ->
    CozyInstance.first (err, instance) ->
        callback err, instance?.locale or 'en'
