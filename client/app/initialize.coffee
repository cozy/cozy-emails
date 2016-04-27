# Styles loads
require '../vendor/print-helper.css'
require 'bootstrap/dist/css/bootstrap-theme.css'
require 'bootstrap/dist/css/bootstrap.css'
# Bootstrap loads (need jQuery to be injected)
require 'imports?jQuery=jquery!bootstrap/dist/js/bootstrap.js'

{initReporting, sendReport} = require './utils/error_manager'
{initPerformances, logPerformances} = require './utils/perfs_measurement_utils'
{initRealtime} = require './utils/realtime_utils'
{initDesktopNotifications} = require './utils/notification_utils'

ConsoleAPI = require './utils/api_utils'
Router = require './router'


window.__DEV__ = window.location.hostname is 'localhost'

# Waits for the DOM to be ready
document.addEventListener 'DOMContentLoaded', ->

    try
        # initialize system
        initReporting(window.__DEV__)
        initPerformances() if window.__DEV__
        window.cozyMails = ConsoleAPI

        # use Cozy instance locale or navigator language or "en" by default
        window.settings = {} unless window.settings
        locale = window.locale or window.navigator.language or 'en'
        window.cozyMails.setLocale locale

        # init plugins
        PluginUtils = require "./utils/plugin_utils"
        if not window.settings.plugins?
            window.settings.plugins = {}
        PluginUtils.merge window.settings.plugins
        PluginUtils.init()


        # Set default Layout
        LayoutActionCreator = require './actions/layout_action_creator'
        LayoutActionCreator.setDisposition window.settings.layoutStyle

        # Routing management
        initRealtime()
        window.router = new Router()

        # initialize interfaces
        initDesktopNotifications()

        # starts perfs logging
        logPerformances() if window.__DEV__

    catch err
        sendReport 'error', err
