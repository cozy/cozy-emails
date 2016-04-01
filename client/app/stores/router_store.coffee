_         = require 'lodash'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'
AccountStore = require '../stores/account_store'

AppDispatcher = require '../app_dispatcher'

{ActionTypes} = require '../constants/app_constants'

class RouterStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _router = null

    _action = null

    _nextURL = null
    _lastDate = null

    _currentFilter = _defaultFilter =
        field: 'date'
        order: '-'

        # FIXME : est-ce que ce filtre est util?!
        type: null

        flags: null

        value: null
        before: null
        after: null

    getRouter: ->
        return _router

    getAction: ->
        return _action

    # If filters are default
    # Nothing should appear in URL
    getQueryParams: ->
         if _currentFilter isnt _defaultFilter then _currentFilter else null

    getFilter: ->
        _currentFilter

    setFilter: (params={}) ->
        return if params.query and not (params = _getURLparams params.query)

        # Update Filter
        _currentFilter = _.clone _defaultFilter
        _.extend _currentFilter, params

        return _currentFilter

    getScrollValue: ->
        _scrollValue

    getURL: (params={}) ->
        # FIXME : prendre en compte ici le cas
        # conversation.next
        # conversation.previous
        action = _getRouteAction params
        filter = _getURIQueryParams params

        isMessage = !!params.messageID or -1 < action.indexOf 'message'
        if isMessage and not params.mailboxID
            params.mailboxID = AccountStore.getSelectedMailbox()?.get 'id'

        isMailbox = -1 < action.indexOf 'mailbox'
        if isMailbox and not params.mailboxID
            params.mailboxID = AccountStore.getSelected()?.get 'id'

        isAccount = -1 < action.indexOf 'account'
        if isAccount and not params.accountID
            params.accountID = AccountStore.getSelectedOrDefault()?.get 'id'
        if isAccount and not params.tab
            params.tab = 'account'


        if (route = _getRoute action)
            isValid = true
            prefix = unless params.isServer then '#' else ''
            url = route.replace /\:\w*/gi, (match) =>
                # Get Route pattern of action
                # Replace param name by its value
                param = match.substring 1, match.length
                params[param]

            # console.log 'getURL', action, prefix + url.replace(/\/\*$/, '')
            return prefix + url.replace(/\/\*$/, '') + filter

        return '/' + filter

    getNextURL: ->
        return _nextURL

    getCurrentURL: (options={}) ->
        params = _.extend {}, {isServer: true}, options
        params.action = @getAction() unless params.action
        params.mailboxID = AccountStore.getSelectedMailbox()?.get('id')
        return @getURL params

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

    _getURLparams = (query) ->
        # Get data from URL
        if _.isString query
            params = query.match /([\w]+=[-+\w,]+)+/gi
            return unless params?.length

            result = {}
            _.each params, (param) ->
                param = param.split '='
                if -1 < (value = param[1]).indexOf ','
                    value = value.split ','
                if 'sort' is param[0]
                    result['order'] = value.substr 0, 1
                    result['field'] = value.substr 1
                else
                    result[param[0]] = value
            return result

        # Get data from Views
        switch query.type
            when 'from', 'dest'
                result = {}
                result.before = query.value
                result.after = "#{query.value}\uFFFF"

            when 'date'
                if query.range
                    result = {}
                    result.before = query.range[0]
                    result.after = query.range[1]

            when 'flag'
                # Keep previous filters
                flags = _currentFilter.flags or []
                flags = [flags] if _.isString flags

                # Toggle value
                if -1 < flags.indexOf query.value
                    _.pull flags, query.value
                else
                    flags.push query.value
                (result = {}).flags = flags
        return result

    # _getFilterParams = ->
    #     'starred,unread'
    #
    # _getSortParams = ->
    #     'sender:ASC'
    #
    # _getStartDateParams = ->
    #     '2016-03-01T23:00:00.000Z'
    #
    # _getEndDateParams = ->
    #     '2016-03-03T22:59:59.999Z'

    _getURIQueryParams = (params) ->
        filters = _self.getFilter()
        params = _.extend {}, filters, params?.filter
        result = ''

        # FIXME : adapter les URL
        # à l'API côté serveur
        if params.isServer
            sortField = params.order + '' + params.field
            params.sort = sortField
            delete params.order
            delete params.field

            _.each params, (value, key) ->
                if value
                    result = '/?' unless result.length
                    result += key + '=' + value + '&'

        else
            _.each params, (value, key) ->
                if value and _defaultFilter[key] isnt value
                    result = '/?' unless result.length
                    result += key + '=' + value + '&'
        result


    _getSort = (filter) ->
        filter = _self.getFilter() unless filter

        value = filter.field
        value = filter.type if _self.isResetFilter filter
        encodeURIComponent "#{filter.order}#{value}"

    _resetFilter = ->
        _currentFilter = _defaultFilter

    # Useless for MessageStore
    # to clean messages
    isResetFilter: (filter) ->
        filter = _self.getFilter() unless filter
        filter.type in ['from', 'dest']


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.QUERY_PARAMETER_CHANGED, (params) ->
            _self.setFilter params
            @emit 'change'

        handle ActionTypes.SET_ROUTE_ACTION, (value) ->
            _action = value
            @emit 'change'

        handle ActionTypes.SAVE_ROUTES, (router) ->
            _router = router
            @emit 'change'

        handle ActionTypes.MESSAGE_FETCH_SUCCESS, (params) ->
            newDate = params.nextURL?.match(/pageAfter=[\w-%.]*&*/gi)
            newDate = newDate?[0].split('=')[1]

            # PageAfter should get older Messages
            # if not do not change _nextPage
            if not _lastDate or _lastDate > newDate
                _nextURL = params.nextURL
                _lastDate = newDate
            @emit 'change'

        handle ActionTypes.SELECT_ACCOUNT, (value) ->
            _resetFilter()
            @emit 'change'

        handle ActionTypes.MESSAGE_TRASH_SUCCESS, (params) ->
            if 'message.show' is _action
                if (messageID = params?.next?.get 'id')
                    _router.navigate @getURL {messageID}
                else
                    _action = 'message.list'
                @emit 'change'

_toCamelCase = (value) ->
    return value.replace /\.(\w)*/gi, (match) ->
        part1 = match.substring 1, 2
        part2 = match.substring 2, match.length
        return part1.toUpperCase() + part2


module.exports = (_self = new RouterStore())
