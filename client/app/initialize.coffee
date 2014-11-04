# Waits for the DOM to be ready
window.onload = ->

    window.__DEV__ = window.location.hostname is 'localhost'

    # expose an API
    window.cozyMails = require './utils/api_utils'

    # use Cozy instance locale or navigator language or "en" by default
    if not window.settings?
        window.settings = {}
    locale =
        window.settings.lang or
        window.locale or
        window.navigator.language or
        "en"

    window.cozyMails.setLocale locale

    # init plugins
    PluginUtils = require "./utils/plugin_utils"
    if not window.settings.plugins?
        window.settings.plugins = {}
    PluginUtils.merge window.settings.plugins
    PluginUtils.init()

    window.cozyMails.setSetting 'plugins', window.settings.plugins

    # Flux initialization (must be called at the begining)
    AccountStore  = require './stores/account_store'
    LayoutStore   = require './stores/layout_store'
    MessageStore  = require './stores/message_store'
    SettingsStore = require './stores/settings_store'
    SearchStore   = require './stores/search_store'

    # Routing management
    Router = require './router'
    @router = new Router()
    window.router = @router

    # Binds the router and flux to the React application
    Application = require './components/application'
    application = Application router: @router
    React.renderComponent application, document.body
    SettingsActionCreator = require './actions/settings_action_creator/'
    SettingsActionCreator.setRefresh window.settings.refreshInterval

    # Starts the application by initializing the router
    Backbone.history.start()

    # begin realtime
    require './utils/socketio_utils'
