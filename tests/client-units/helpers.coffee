exports.initGlobals = ->
    global.Immutable = require 'immutable'
    global.EventEmitter = require('events').EventEmitter
    global.t = (x) -> "translated #{x}"
    global.__DEV__ = true
    global.window = cozyMails:
        logAction: ->
        customEvent: ->

exports.setWindowVariable = (windowVariable) ->
    global.window[k] = v for k, v of windowVariable

requireNoCache = (modulePath) ->
    absPath = require('path').resolve __dirname, modulePath
    modulePathResolved = require.resolve absPath
    delete require.cache[modulePathResolved]
    return require modulePathResolved

exports.getCleanStore = (which) ->
    Dispatcher = requireNoCache '../../client/app/app_dispatcher'
    Store = requireNoCache "../../client/app/stores/#{which}"
    dispatch = (type, value) -> Dispatcher.handleViewAction {type, value}
    return {dispatch, Store}
