# Waits for the DOM to be ready
$ ->

    # Fluxxor initialization (model)
    flux = require './fluxxor'

    # Routing management
    Router = require 'router'
    @router = new Router flux: flux
    window.router = @router

    # Binds the router and flux to the React application
    Application = require './components/application'
    application = Application router: @router, flux: flux
    React.renderComponent application, document.body


    # Starts the application by initializing the router
    Backbone.history.start()


    # Makes this object immuable.
    Object.freeze this if typeof Object.freeze is 'function'