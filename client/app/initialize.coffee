# Styles loads
require '../vendor/print-helper.css'
require 'bootstrap/dist/css/bootstrap-theme.css'
require 'bootstrap/dist/css/bootstrap.css'
# Bootstrap loads (need jQuery to be injected)
require 'imports?jQuery=jquery!bootstrap/dist/js/bootstrap.js'

{initReporting, sendReport} = require './utils/error_manager'
{initPerformances} = require './utils/perfs_measurement_utils'
{initRealtime} = require './utils/realtime_utils'
{initDesktopNotifications} = require './utils/notification_utils'

Router = require './router'

# Waits for the DOM to be ready
document.addEventListener 'DOMContentLoaded', ->

    try
        window.__DEV__ = window.location.hostname is 'localhost'

        # Initialize system
        initReporting()
        initPerformances()

        # Routing management
        new Router()

        # Initialize discussions
        initRealtime()
        initDesktopNotifications()

    catch err
        sendReport 'error', err
