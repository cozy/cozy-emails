Backbone = require 'backbone'
React    = require 'react'
ReactDOM = require 'react-dom'

RouterGetter = require './getters/router'

RouterActionCreator = require './actions/router_action_creator'

{ActionTypes} = require './constants/app_constants'

routes = require './routes'
reduxStore = require './redux_store'

Polyglot = require 'node-polyglot'
moment   = require 'moment'

# MessageList :
# ?sort=asc&filters=&status=unseen&start=2016-02-27T23:00:00.000Z&end=2016-03-05T22:59:59.999Z

class Router extends Backbone.Router

    routes: routes.BACKBONE_ROUTES

    initialize: ->
        _setLocale()

        @on 'route', @onRouteMatched

        # Start Navigation
        # Listening to route changes
        # Update views from this changes
        Backbone.history.start()

        # Call this after handling route
        # not to freeze route redirections
        # and handle default, error cases
        # Display application
        _displayApplication()

        # Listening to dispatches
        # update components
        reduxStore.subscribe @onDispatch


    onRouteMatched: (name, paramsValues)->
        return @defaultView() if name is 'DEFAULT'
        [action, name, ..., paramsNames] = routes.ROUTE_BY_ACTION[name]
        params = {action: action}
        params[name] = paramsValues[i] for name, i in paramsNames
        params.filter = _parseQuery(params.filter) if params.filter

        reduxStore.dispatch
            type: ActionTypes.ROUTE_CHANGE
            value: params

        if params.mailboxID?
            # Always get freshest data as possible
            RouterActionCreator.refreshMailbox reduxStore.dispatch,
                mailboxID: params.mailboxID

            # Get all messages to display messages list
            RouterActionCreator.getCurrentPage reduxStore.dispatch

        # Get all messages from conversation
        if params.conversationID?
            RouterActionCreator.getConversation reduxStore.dispatch,
                params.conversationID


    onDispatch: =>
        urlShouldBe = RouterGetter.getCurrentURL reduxStore.getState()
        if location?.hash isnt urlShouldBe
            @navigate urlShouldBe, trigger: false


# Extract params from q queryString to an object that map `key` > `value`.
# Extracted values can be:
# - a simple string: `?foo=bar` > {foo: 'bar'}
# - an array (comma separator): `?foo=bar,23` > {foo: ['bar', '23']}
# - an object (colon separator): `?foo=dest:asc` > {foo: {dest: 'asc'}}
# - a boolean mapped to true: `?foo` > {foo: true}
_parseQuery = (query) ->
    params = {}
    parts = query.split '&'
    for part in parts
        [param, value] = part.split '='
        params[param] = if /,/g.test value
            value.split ','
        else if /:/.test value
            [arg, val] = value.split ':'
            (obj = {})[arg] = val
            obj
        else
            value or true
    return params


_displayApplication = ->
    Application = require './components/application'
    app = React.createElement Application, store: reduxStore
    ReactDOM.render app, document.querySelector '[role=application]'


# update locale value
# without saving it into settings
_setLocale = (lang) ->
    lang ?= window.locale or window.navigator.language or 'en'
    moment.locale lang

    locales = {}
    try
        locales = require "./locales/#{lang}"
    catch err
        console.log err
        locales = require "./locales/en"

    polyglot = new Polyglot()
    polyglot.extend locales

    # FIXME : is this the way to do it?
    # FIXME : is this the place to do that stuff?
    # handy shortcut
    window.t = polyglot.t.bind polyglot


module.exports = Router
