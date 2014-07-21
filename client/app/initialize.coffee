
# Waits for the DOM to be ready
$ ->
    # Routing management
    Router = require 'router'
    RouterInterface = require './lib/router-interface'

    # Binds the Backbone Router to the React application
    @router = new Router()
    React.renderComponent  RouterInterface(router: @router), document.body

    # Starts the application by initializing the router
    Backbone.history.start()

    # Makes this object immuable.
    Object.freeze this if typeof Object.freeze is 'function'