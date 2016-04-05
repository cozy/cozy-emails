_         = require 'lodash'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'
AccountStore = require '../stores/account_store'

AppDispatcher = require '../app_dispatcher'

{ActionTypes, MessageActions, AccountActions} = require '../constants/app_constants'

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
        sort: '-'

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
        # next conversation : MessageActions.GROUP_NEXT
        # previous conversation : MessageActions.GROUP_PREVIOUS
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
        params = _.extend {isServer: true}, options
        params.action = @getAction() unless params.action
        params.mailboxID = AccountStore.getSelectedMailbox()?.get('id')
        return @getURL params

    _getRouteAction = (params) ->
        unless (action = params.action)
            return MessageActions.SHOW if params.messageID
            return MessageActions.SHOW_ALL
        action

    _getRoute = (action) ->
        routes = _router.routes
        name = _toCamelCase action
        index = _.values(routes).indexOf(name)
        _.keys(routes)[index]

    _getURLparams = (query) ->
        # Get data from URL
        if _.isString query
            params = query.match /([\w]+=[-+\w,:.]+)+/gi
            return unless params?.length
            result = {}

            _.each params, (param) ->
                param = param.split '='
                if -1 < (value = param[1]).indexOf ','
                    value = value.split ','
                else
                    result[param[0]] = value

            return result

        # Get data from Views
        switch query.type
            when 'from', 'dest'
                result = {}
                result.before = query.value
                result.after = "#{query.value}\uFFFF"

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

    _getURIQueryParams = (params) ->
        filters = _self.getFilter()
        isServer = params.isServer
        params = _.extend {}, filters, params?.filter
        result = ''

        if isServer
            params.sort = "#{params.sort}date"
            _.each params, (value, key) ->
                if value and value isnt 'undefined'
                    start = unless result.length then '/?' else '&'
                    result += start + key + '=' + encodeURIComponent(value)
        else
            _.each params, (value, key) ->
                if value and value isnt 'undefined' and _defaultFilter[key] isnt value
                    start = unless result.length then '/?' else '&'
                    result += start + key + '=' + value
        result

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

        handle ActionTypes.ROUTE_CHANGE, (value) ->
            _action = value
            @emit 'change'

        handle ActionTypes.ROUTES_INITIALIZE, (router) ->
            _router = router
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, ->
            _router?.navigate url: ''

        handle ActionTypes.ADD_ACCOUNT_SUCCESS, ({account, areMailboxesConfigured}) ->
            accountID = account.id
            action = if areMailboxesConfigured then MessageActions.SHOW_ALL else AccountActions.EDIT
            _router?.navigate {accountID, action}
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
            if MessageActions.SHOW is _action
                if (messageID = params?.next?.get 'id')
                    _router.navigate @getURL {messageID}
                else
                    _action = MessageActions.SHOW_ALL
                @emit 'change'

_toCamelCase = (value) ->
    return value.replace /\.(\w)*/gi, (match) ->
        part1 = match.substring 1, 2
        part2 = match.substring 2, match.length
        return part1.toUpperCase() + part2


module.exports = (_self = new RouterStore())
