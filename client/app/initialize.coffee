# Styles loads
require '../vendor/print-helper.css'
require 'bootstrap/dist/css/bootstrap-theme.css'
require 'bootstrap/dist/css/bootstrap.css'
# Bootstrap loads (need jQuery to be injected)
require 'imports?jQuery=jquery!bootstrap/dist/js/bootstrap.js'

Notification = require './libs/notification'
Router = require './router'
Reporting = require './libs/reporting'
Realtime = require './libs/realtime'
Performances = require './libs/performances'
reduxStore = require './reducers/_store'

document.addEventListener 'DOMContentLoaded', ->

    __DEV__ = window.location.hostname is 'localhost'
    window.__DEV__ = __DEV__

    # External notifications
    Reporting.initialize()
    try
        Performances.initialize() if __DEV__
        Notification.initialize()
        Realtime.initialize(reduxStore.dispatch)
    catch err
        console.error err
        Reporting.report(err)

    # Routing management
    new Router()
