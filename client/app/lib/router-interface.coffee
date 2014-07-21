Application = require '../components/application'

###
    The RouterInterface uses Backbone.Router as a source of truth
    and is the binding between the router and the React application.
    Based on https://medium.com/react-tutorials/react-backbone-router-c00be0cf1592
###

module.exports = React.createClass
    displayName: 'RouterInterface'

    componentWillMount: ->
        # Uses `forceUpdate` with the proper scope because React doesn't allow
        # to rebind its scope on the fly
        @callback = => @forceUpdate()

        @props.router.on 'route', @callback

    componentWillUnmount: ->
        @props.router.off 'route', @callback

    render: ->
        if @props.router.current is 'main'
            return Application()
        else
            return React.DOM.div null, ''