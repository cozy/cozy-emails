# Styles loads
require '../vendor/print-helper.css'
require 'bootstrap/dist/css/bootstrap-theme.css'
require 'bootstrap/dist/css/bootstrap.css'
# Bootstrap loads (need jQuery to be injected)
require 'imports?jQuery=jquery!bootstrap/dist/js/bootstrap.js'

Notification = require './libs/notification'
Router = require './router'

document.addEventListener 'DOMContentLoaded', ->

    window.__DEV__ = window.location.hostname is 'localhost'

    # External notifications
    Notification.initialize()

    # Routing management
    new Router()
