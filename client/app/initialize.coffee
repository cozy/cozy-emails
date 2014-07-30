# Waits for the DOM to be ready
$ ->

    # Fluxxor initialization (model)
    MailboxStore = require './stores/mailboxes'
    EmailStore = require './stores/emails'
    LayoutStore = require './stores/layout'

    stores =
        MailboxStore: new MailboxStore()
        EmailStore: new EmailStore()
        LayoutStore: new LayoutStore()

    actions =
        layout: require './actions/layout_actions'

    flux = new Fluxxor.Flux stores, actions


    # Routing management
    Router = require 'router'
    @router = new Router flux: flux
    window.router = @router

    # Starts the application by initializing the router
    Backbone.history.start()


    # Binds the router and flux to the React application
    Application = require './components/application'
    application = Application router: @router, flux: flux
    React.renderComponent application, document.body


    # Makes this object immuable.
    Object.freeze this if typeof Object.freeze is 'function'