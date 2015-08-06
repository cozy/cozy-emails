
{EventEmitter} = require 'events'
_ = require 'lodash'

# using DS events imply one more query for each update
# instead we monkeypatch cozydb
module.exports.wrapModel = (Model) ->

    Model.ee = new EventEmitter()

    Model.on = -> Model.ee.on.apply Model.ee, arguments

    _oldCreate = Model.create
    Model.create = (data, callback) ->
        _oldCreate.call Model, data, (err, created) ->
            Model.ee.emit 'create', created unless err
            callback err, created

    _oldUpdateAttributes = Model::updateAttributes
    Model::updateAttributes = (data, callback) ->
        old = _.cloneDeep @toObject()
        _oldUpdateAttributes.call this, data, (err, updated) =>
            Model.ee.emit 'update', this, old unless err
            callback err, updated

    _oldDestroy = Model::destroy
    Model::destroy = (callback) ->
        old = @toObject()
        id = old.id
        _oldDestroy.call this, (err) ->
            Model.ee.emit 'delete', id, old unless err
            callback err

    return Model
