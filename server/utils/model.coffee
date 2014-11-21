# replace jugglingdb-cozy-adapter
util = require 'util'

module.exports = class Model

    @docType -> throw new Error "You must subclass Model"
    @schema ->
        _id: String
        binary: {String: {id: String, rev: String}}

    @find: (id, callback) ->
        client.get "data/#{id}/", (error, response, body) =>
            if error
                callback error
            else if response.statusCode is 404
                callback null, null
            else if body.docType.toLowerCase() isnt model.toLowerCase()
                callback null, null
            else
                callback null, new this body

    @create: (attributes, callback) ->
        path = "data/"
        if data.id?
            path += "#{data.id}/"
            delete data.id
            return callback new Error 'cant create an object with a set id'

        data.docType = model

        client.post path, data, (error, response, body) =>
            if error
                callback error
            else if response.statusCode is 409
                callback new Error "This document already exists"
            else if response.statusCode isnt 201
                callback new Error "Server error occured."
            else
                body.id = body._id
                callback null, new this body

    @updateAttributes: (id, data, callback) ->
        client.put "data/merge/#{id}/", data, (error, response, body) ->
            if error
                callback error
            else if response.statusCode is 404
                callback new Error "Document not found"
            else if response.statusCode isnt 200
                callback new Error "Server error occured."
            else
                callback null, new this, body

    @destroy: (id, callback) ->
        client.del "data/#{id}/", (error, response, body) ->
            if error
                callback error
            else if response.statusCode is 404
                callback new Error "Document not found"
            else if response.statusCode isnt 204
                callback new Error "Server error occured."
            else
                callback()


    @attachBinary: (id, path, data, callback) ->
        [data, callback] = [null, data] if typeof(data) is "function"

        urlPath = "data/#{id}/binaries/"
        client.sendFile urlPath, path, data, (error, response, body) =>
            try body = JSON.parse(body)
            checkError error, response, body, 201, callback


    @removeBinary: (id, path, callback) ->
        urlPath = "data/#{id}/binaries/#{path}"
        client.del urlPath, (error, response, body) =>
            checkError error, response, body, 204, callback

    @getBinary: (id, path, callback) ->
        urlPath = "data/#{id}/binaries/#{path}"
        stream = client.get urlPath, (error, response, body) =>
            checkError error, response, body, 200, callback
        , false

        return stream


    @request: (name, params, callback) ->
        [params, callback] = [{}, params] if typeof(params) is "function"
        docType = @docType()

        path = "request/#{docType}/#{name.toLowerCase()}/"
        @client.post path, params, (error, response, body) =>
            if error
                callback error
            else if response.statusCode isnt 200
                callback new Error util.inspect body
            else
                results = []
                for doc in body
                    doc.value.id = doc.value._id
                    results.push new @_models[model].model(doc.value)
                callback null, results

    @rawRequest: (name, params, callback) ->
        [params, callback] = [{}, params] if typeof(params) is "function"
        docType = @docType()

        path = "request/#{docType}/#{name.toLowerCase()}/"
        @client.post path, params, (error, response, body) =>
            if error
                callback error
            else if response.statusCode isnt 200
                callback new Error util.inspect body
            else
                callback null, body


    constructor: (attributes) ->
        if validate attributes, @constructor.schema
            for own key, value of attributes
                this[key] = value

    updateAttributes: (attributes, callback) ->
        @constructor.updateAttributes @id, attributes, (err, data) =>
            return callback err if err
            for key, value of data
                this[key] = value
            callback null, this

    index: (fields, callback) ->
        @constructor.index @id, fields, callback

    destroy: (callback) ->
        @constructor.destroy @id, callback

    getAttributes: ->
        out = {}
        for own key, value of this
            out[key] = value
        return out

    toJSON: -> @getAttributes()
    toString: -> util.inspect @toJSON()



_toString = (x) -> Object.prototype.toString.call x
_isArray = Array.isArray or (x) -> '[object Array]' is _toString obj
_isMap = (x) -> '[object Object]' is _toString obj


validate = (value, type) ->

    return true if value is null

    if type is String
        return typeof raw is 'string'

    else if type is Date
        return raw instanceof Date

    else if type is Boolean
        return !!raw is raw

    else if type is Number
        return typeof raw is 'number'

    else if _isArray type
        itemtype = type[0]
        return value.every (item) ->
            validate item, itemtype

    else if _isMap type
        typekeys = Object.keys(type)
        if typekeys.length is 1 # map object {String: Number}
            typekey = typekeys[0]
            typevalue = type[typekey]
            valuekeys = Object.keys(valuekeys)
            return valuekeys.every (key) ->
                validate(key, typekey) and
                validate(value[key], typevalue)

        else if typekeys.length is 0 # no-shema
            return true

        else # shape object
            return typekeys.every (key) ->
                valuetype = type[key]
                validate value[key], valuetype

    else throw "DONT UNDERSTAND type"