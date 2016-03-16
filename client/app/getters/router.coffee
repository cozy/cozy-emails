AccountStore = require '../stores/account_store'

_ = require 'lodash'

class RouteGetter

    _routes: null

    getPrefixedRoute: (routes, prefix) ->
        _transform = (route) ->
            unless -1 < route.indexOf 'account'
                route = '/' + route unless route.indexOf('/') is 0
                return prefix + route
            return route

        _routes = {}
        _.forEach routes, (callback, route) ->
            route = _transform route
            _routes[route] = callback
        @_routes = _routes
        _routes

    getURLparams: (query = '') ->
        params = query.match /([\w]+=[\w,]+)+/gi
        return unless params?.length

        result = {}
        _.each params, (param) ->
            param = param.split '='
            if -1 < (value = param[1]).indexOf ','
                value = value.split ','
            result[param[0]] = value
        result

    getURL: (params) ->
        action = _getRouteAction params
        name = _toCamelCase action

        if -1 < (index = _.values(@_routes).indexOf(name))
            route = _.keys(@_routes)[index]
            url = route.replace /\:\w*/gi, (match) =>
                # Get Route pattern of action
                # Replace param name by its value
                param = match.substring 1, match.length
                params[param] or @getProps(param)
            # console.log 'getURL', action, url.replace(/\/\*$/, '')
            return '#' + url.replace(/\/\*$/, '')
        return '/'

    getProps: (name) ->
        if 'accountID' is name
            return AccountStore.getSelectedOrDefault()?.get 'id'
        if 'mailboxID' is name
            return AccountStore.getSelectedMailbox()?.get 'id'
        if 'tab' is name
            return ''

_getRouteAction = (params) ->
    unless (action = params.action)
        return 'message.show' if params.messageID
        return 'message.list'
    action

_toCamelCase = (value) ->
    return value.replace /\.(\w)*/gi, (match) ->
        part1 = match.substring 1, 2
        part2 = match.substring 2, match.length
        return part1.toUpperCase() + part2

module.exports = new RouteGetter()
