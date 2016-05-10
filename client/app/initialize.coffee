# Styles loads
require '../vendor/print-helper.css'
require 'bootstrap/dist/css/bootstrap-theme.css'
require 'bootstrap/dist/css/bootstrap.css'
# Bootstrap loads (need jQuery to be injected)
require 'imports?jQuery=jquery!bootstrap/dist/js/bootstrap.js'

Router = require './router'

# Waits for the DOM to be ready
document.addEventListener 'DOMContentLoaded', ->

    window.__DEV__ = window.location.hostname is 'localhost'

    # Routing management
    new Router()
