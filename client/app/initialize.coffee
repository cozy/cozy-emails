# expose an API for performance
# performance is not defined in phantomJS
initPerformances = ->
    referencePoint = 0
    window.start = ->
        referencePoint = performance.now() if performance?.now?
        React.addons.Perf.start()
    window.stop = ->
        console.log performance.now() - referencePoint if performance?.now?
        React.addons.Perf.stop()
    window.printWasted = ->
        stop()
        React.addons.Perf.printWasted()
    window.printInclusive = ->
        stop()
        React.addons.Perf.printInclusive()
    window.printExclusive = ->
        stop()
        React.addons.Perf.printExclusive()

logPerformances = ->
    timing = window.performance?.timing
    now = Math.ceil window.performance?.now()
    if timing?
        message  = "Response: #{timing.responseEnd - timing.navigationStart}ms"
        message += ", Onload: #{timing.loadEventStart - timing.navigationStart}ms"
        message += ", Page loaded: #{now}ms"
        window.cozyMails.logInfo message

# Init Web Intents
initIntent = ->
    IntentManager = require "./utils/intent_manager"
    window.intentManager = new IntentManager()
    window.intentManager.send 'nameSpace',
        type: 'ping'
        from: 'mails'
    .then (message) ->
        LayoutActionCreator.intentAvailability true
    , (error) ->
        LayoutActionCreator.intentAvailability false

# init plugins
initPlugins = ->
    PluginUtils = require "./utils/plugin_utils"
    if not window.settings.plugins?
        window.settings.plugins = {}
    PluginUtils.merge window.settings.plugins
    PluginUtils.init()

# Send client side errors to server
window.onerror = (msg, url, line, col, error) ->
    console.error msg, url, line, col, error, error?.stack
    exception = error?.toString() or msg
    if exception isnt window.lastError
        data =
            data:
                type: 'error'
                error:
                    msg: msg
                    name: error?.name
                    full: exception
                    stack: error?.stack
                url: url
                line: line
                col: col
                href: window.location.href
        xhr = new XMLHttpRequest()
        xhr.open 'POST', 'activity', true
        xhr.setRequestHeader "Content-Type", "application/json;charset=UTF-8"
        xhr.send JSON.stringify(data)
        window.lastError = exception

# Waits for the DOM to be ready
document.addEventListener 'DOMContentLoaded', ->

    try
        window.__DEV__ = window.location.hostname is 'localhost'

        initPerformances()

        # expose an API
        window.cozyMails = require './utils/api_utils'

        # use Cozy instance locale or navigator language or "en" by default
        if not window.settings?
            window.settings = {}
        locale =
            #window.settings.lang or
            window.locale or
            window.navigator.language or
            "en"

        window.cozyMails.setLocale locale
        LayoutActionCreator = require './actions/layout_action_creator/'
        LayoutActionCreator.setDisposition window.settings.layoutStyle

        # init plugins
        PluginUtils = require "./utils/plugin_utils"
        if not window.settings.plugins?
            window.settings.plugins = {}
        PluginUtils.merge window.settings.plugins
        PluginUtils.init()

        window.cozyMails.setSetting 'plugins', window.settings.plugins

        # Init Web Intents
        initIntent()

        # Flux initialization (must be called at the begining)
        AccountStore  = require './stores/account_store'
        ContactStore  = require './stores/contact_store'
        LayoutStore   = require './stores/layout_store'
        MessageStore  = require './stores/message_store'
        SettingsStore = require './stores/settings_store'

        # Routing management
        Router = require './router'
        @router = new Router()
        window.router = @router

        # Binds the router and flux to the React application
        Application = require './components/application'
        application = Application router: @router
        window.rootComponent = React.renderComponent application, document.body

        # Starts the application by initializing the router
        Backbone.history.start()

        # begin realtime
        require './utils/socketio_utils'

        # Desktop notifications
        if window.settings.desktopNotifications and window.Notification?
            Notification.requestPermission (status) ->
                # This allows to use Notification.permission with Chrome/Safari
                if Notification.permission isnt status
                    Notification.permission = status

        logPerformances()

        window.cozyMails.customEvent "APPLICATION_LOADED"

    catch e
        console.error e, e?.stack
        exception = e.toString()
        if exception isnt window.lastError
            # Send client side errors to server
            data =
                data:
                    type: 'error'
                    error:
                        msg: e.message
                        name: e?.name
                        full: exception
                        stack: e?.stack
                    file: e?.fileName
                    line: e?.lineNumber
                    col: e?.columnNumber
                    href: window.location.href
            xhr = new XMLHttpRequest()
            xhr.open 'POST', 'activity', true
            xhr.setRequestHeader "Content-Type",
                "application/json;charset=UTF-8"
            xhr.send JSON.stringify(data)
            window.lastError = exception
