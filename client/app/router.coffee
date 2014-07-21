###
    Very simple routing component. We let Backbone handling browser stuff
    and we bind it to the React application with the `RouterInterface`
###

module.exports = class Router extends Backbone.Router

    routes:
        '': 'main'

    main: -> @current = 'main'