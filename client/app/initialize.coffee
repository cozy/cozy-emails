# Styles loads
require '../vendor/print-helper.css'
require 'bootstrap/dist/css/bootstrap-theme.css'
require 'bootstrap/dist/css/bootstrap.css'
# Bootstrap loads (need jQuery to be injected)
require 'imports?jQuery=jquery!bootstrap/dist/js/bootstrap.js'

{initReporting, sendReport} = require './utils/error_manager'

ApiUtils = require './utils/api_utils'
Router = require './router'


window.__DEV__ = window.location.hostname is 'localhost'

# Waits for the DOM to be ready
document.addEventListener 'DOMContentLoaded', ->

    try
        # initialize system
        initReporting(window.__DEV__)
        initPerformances() if window.__DEV__

        # Routing management
        new Router()

        # starts perfs logging
        if window.__DEV__
            if (message = logPerformances())
                ApiUtils.logInfo message


    catch err
        sendReport 'error', err
