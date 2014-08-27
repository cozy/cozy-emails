$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$ = $
React    = require 'react/addons'
Polyglot = require 'node-polyglot'
moment   = require 'moment'


# Haven't managed to make bootstrap.dropdown relies on jQuery
# in a proper "browserify" way
window.jQuery = $
require 'bootstrap/js/dropdown'


# Waits for the DOM to be ready
window.onload = ->

    # use Cozy instance locale or navigator language or "en" by default
    locale = window.locale or window.navigator.language or "en"
    moment.locale locale
    locales = {}
    try
        locales = require "./locales/#{locale}"
    catch err
        console.log err
        locales = require "./locales/en"
    polyglot = new Polyglot()
    # we give polyglot the data
    polyglot.extend locales
    # handy shortcut
    window.t = polyglot.t.bind polyglot


    # Flux initialization (must be called at the begining)
    LayoutStore = require './stores/LayoutStore'
    MessageStore = require './stores/MessageStore'
    AccountStore = require './stores/AccountStore'
    MailboxStore = require './stores/MailboxStore'

    # Routing management
    Router = require './router'
    @router = new Router()
    window.router = @router

    # Binds the router and flux to the React application
    Application = require './components/application'
    application = Application router: @router
    React.renderComponent application, document.body


    # Starts the application by initializing the router
    Backbone.history.start()


    # Makes this object immuable.
    Object.freeze this if typeof Object.freeze is 'function'
