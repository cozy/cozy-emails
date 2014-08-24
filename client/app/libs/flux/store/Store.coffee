{EventEmitter} = require 'events'
AppDispatcher = require '../../../AppDispatcher'

module.exports = class Store extends EventEmitter

    # this variable will be shared with all subclasses so we store the items by subclass
    _handlers = {}
    _addHandlers = (type, callback) ->
        storeName = @constructor.name
        _handlers[storeName] = {} unless _handlers[storeName]?
        _handlers[storeName][type] = callback

    # Registers the store's callbacks to the dispatcher
    _processBinding = ->
        storeName = @constructor.name
        @dispatchToken = AppDispatcher.register (payload) =>
            {type, value} = payload.action
            if (callback = _handlers[storeName][type])? then callback.call @, value

        console.log "#{storeName} -- #{@dispatchToken}"


    constructor: ->
        super()
        @__bindHandlers _addHandlers.bind @
        _processBinding.call @

    # Must be overriden by each store
    __bindHandlers: (handle) -> throw new Error "The store #{@constructor.name} must define a `__bindHandlers` method"

