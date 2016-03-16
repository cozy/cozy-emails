_         = require 'underscore'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'
AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'

AppDispatcher = require '../app_dispatcher'

{ActionTypes} = require '../constants/app_constants'

class RouterStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _router = null
    _action = null
    _nextUrl = null

    _currentFilter = null

    getRouter: ->
        return _router

    getAction: ->
        return _action

    getURL: (params={}) ->
        action = _getRouteAction params

        # FIXME : adapter les URL
        # à l'API côté serveur
        isServer = params.isServer
        unless isServer
            filter = _getURIQueryParams()
        else
            filter = _getURIServerQueryParams()

        if (route = _getRoute action)
            prefix = unless isServer then '#' else ''
            url = route.replace /\:\w*/gi, (match) =>
                # Get Route pattern of action
                # Replace param name by its value
                param = match.substring 1, match.length
                params[param] or @getProps(param)
            # console.log 'getURL', action, prefix + url.replace(/\/\*$/, '')
            return prefix + url.replace(/\/\*$/, '') + filter

        return '/' + filter

    getNextURL: ->
        return _nextUrl

    getCurrentURL: (params) ->
        _.extend params,
            action: params.action or @getAction()
            isServer: true
        return @getURL params

    # FIXME : plante sur l'affichage du message
    # car doit etre présent plusieurs fois
    getProps: (name) ->
        if 'route' is name
            return @getAction()
        if 'messageID' is name
            return MessageStore.getCurrentID()
        if 'accountID' is name
            return AccountStore.getSelectedOrDefault()?.get 'id'
        if 'mailboxID' is name
            return AccountStore.getSelectedMailbox()?.get 'id'
        # FIXME : gérer ça
        # TODO : trouver les cas d'usages
        # TODO : voir où récupérer la valeur
        if 'tab' is name
            return ''

    getFilter: (getDefault) ->
        # getQueryParams
        #         sort: _getSort()
        #         type: filter.type
        #         filter: filter.value
        #         before: filter.before
        #         after: filter.after
        #         hasNextPage: not _noMore
        return if not _currentFilter or getDefault
            field: 'date'
            order: '-'
            type: '-'
            value: 'nofilter'
            before: '-'
            after: '-'
        return _currentFilter

    _getRouteAction = (params) ->
        unless (action = params.action)
            return 'message.show' if params.messageID
            return 'message.list'
        action

    _getRoute = (action) ->
        routes = _router.routes
        name = _toCamelCase action
        index = _.values(routes).indexOf(name)
        _.keys(routes)[index]

    _getURLparams: (query = '') ->
        params = query.match /([\w]+=[\w,]+)+/gi
        return unless params?.length

        result = {}
        _.each params, (param) ->
            param = param.split '='
            if -1 < (value = param[1]).indexOf ','
                value = value.split ','
            result[param[0]] = value
        result

    _getFilterParams = ->
        'starred,unread'

    _getSortParams = ->
        'sender:ASC'

    _getStartDateParams = ->
        '2016-03-01T23:00:00.000Z'

    _getEndDateParams = ->
        '2016-03-03T22:59:59.999Z'

    _getURIQueryParams = ->
        params = _self.getFilter()
        defaultParams = _self.getFilter true
        result = ''
        _.each params, (value, key) ->
            if defaultParams[key] isnt value and _isFilterEmpty(value)
                result = '/?' unless result.length
                result += key + '=' + value + '&'
        result

    _getURIServerQueryParams = ->
        params = _self.getFilter()
        defaultParams = _self.getFilter true
    #     url = "mailbox/#{mailboxID}/?sort=#{sort}"
    #     if filter.type is 'flag' and _not _isFilterEmpty filter.value
    #         url += "&flag=#{filter.value}"
    #
    #     unless _isFilterEmpty filter.before
    #         url += "&before=#{encodeURIComponent filter.before}"
    #
    #     unless _isFilterEmpty filter.after
    #         url += "&after=#{encodeURIComponent filter.after}"
    #     return url
        '/?sort=-date'

    _isFilterEmpty = (value) ->
        if value
            return value is '-' or value is 'nofilter'
        !!value

    _getSort = (filter) ->
        filter = _self.getFilter() unless filter

        value = filter.field
        value = filter.type if _self.isResetFilter filter
        encodeURIComponent "#{filter.order}#{value}"

    _setFilter = (params) ->
        _defaultValue = _self.getFilter()

        # Update Filter
        _currentFilter =
            field: if params.sort then params.sort.substr(1) else _defaultValue.field
            order: if params.sort then params.sort.substr(0, 1) else _defaultValue.order
            type: params.type or _defaultValue.type
            value: params.flag or _defaultValue.value
            before: params.before or _defaultValue.before
            after: params.after or _defaultValue.after

        # Update context
        _noMore = false
        _nextUrl = null

        return _currentFilter

    _resetFilter = ->
        value = _self.getFilter true
        _setFilter value

    # Useless for MessageStore
    # to clean messages
    isResetFilter: (filter) ->
        filter = _self.getFilter() unless filter
        filter.type in ['from', 'dest']


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.QUERY_PARAMETER_CHANGED, (query) ->
            params =_getURLparams query
            _setFilter params
            @emit 'change'

        handle ActionTypes.SET_ROUTE_ACTION, (value) ->
            _action = value
            @emit 'change'

        handle ActionTypes.SAVE_ROUTES, (router) ->
            _router = router
            @emit 'change'

        handle ActionTypes.SET_NEXT_URL, (value) ->
            _nextUrl = if value then decodeURIComponent value else null
            @emit 'change'

        handle ActionTypes.SELECT_ACCOUNT, (value) ->
            _resetFilter()
            @emit 'change'


_toCamelCase = (value) ->
    return value.replace /\.(\w)*/gi, (match) ->
        part1 = match.substring 1, 2
        part2 = match.substring 2, match.length
        return part1.toUpperCase() + part2


module.exports = (_self = new RouterStore())
