###

RequestsStore
=============

Handles current requests performed in background to let components aware of
their current status.

TODO: when migrating to a stateless server app, all requests status should be
handled by realtime stack and this store should be deprecated.

###

_ = require 'lodash'

Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes
AccountActions
Requests
RequestStatus} = require '../constants/app_constants'


_setRefreshes = (refreshes=[]) ->
    new Immutable.Iterable refreshes
        .toKeyedSeq()
        .mapKeys (_, refresh) -> return refresh.objectID
        .map (refresh) -> Immutable.fromJS refresh
        .toOrderedMap()

_setRequests = ->
    new Immutable.Map
        "#{Requests.DISCOVER_ACCOUNT}": status: null, res: undefined
        "#{Requests.CHECK_ACCOUNT}":    status: null, res: undefined
        "#{Requests.ADD_ACCOUNT}":      status: null, res: undefined


class RequestsStore extends Store

    _requests = _setRequests()

    _refreshes = _setRefreshes window.refreshes


    get: (req) ->
        _requests.get req


    isLoading: (req) ->
        RequestStatus.INFLIGHT is @get(req)?.status


    isRefreshError: ->
        _refreshes.get('errors')?.length


    isRefreshing: ->
        0 isnt _refreshes.size or @isLoading Requests.REFRESH_MAILBOX


    isIndexing: ->
        _.find ['ADD_ACCOUNT', 'INDEX_MAILBOX'], (name) ->
            @isLoading Requests[name]


    __bindHandlers: (handle) ->

        # Assume that when a route 'change', we won't need to keep track of
        # requests anymore, so we reset them
        handle ActionTypes.ROUTE_CHANGE, ->
            _requests = _setRequests()
            @emit 'change'


        handle ActionTypes.DISCOVER_ACCOUNT_REQUEST, ->
            _requests = _requests.set Requests.DISCOVER_ACCOUNT,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.DISCOVER_ACCOUNT_FAILURE, ({error}) ->
            _requests = _requests.set Requests.DISCOVER_ACCOUNT,
                status: RequestStatus.ERROR, res: error
            @emit 'change'


        handle ActionTypes.DISCOVER_ACCOUNT_SUCCESS, ({provider}) ->
            _requests = _requests.set Requests.DISCOVER_ACCOUNT,
                status: RequestStatus.SUCCESS, res: provider
            @emit 'change'


        handle ActionTypes.CHECK_ACCOUNT_REQUEST, ->
            _requests = _requests.set Requests.CHECK_ACCOUNT,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.CHECK_ACCOUNT_FAILURE, ({error, oauth}) ->
            _requests = _requests.set Requests.CHECK_ACCOUNT,
                status: RequestStatus.ERROR, res: {error, oauth}
            @emit 'change'


        handle ActionTypes.CHECK_ACCOUNT_SUCCESS, ({account}) ->
            _requests = _requests.set Requests.CHECK_ACCOUNT,
                status: RequestStatus.SUCCESS, res: account
            @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_REQUEST, ->
            _requests = _requests.set Requests.ADD_ACCOUNT,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_FAILURE, ({error}) ->
            _requests = _requests.set Requests.ADD_ACCOUNT,
                status: RequestStatus.ERROR, res: {error}
            @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_SUCCESS, (res) ->
            _requests = _requests.set Requests.ADD_ACCOUNT,
                status: RequestStatus.SUCCESS, res: res
            @emit 'change'


        handle ActionTypes.RECEIVE_INDEXES_REQUEST, ->
            _requests = _requests.set Requests.INDEX_MAILBOX,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.RECEIVE_ACCOUNT_CREATE, ->
            _requests = _requests.set Requests.ADD_ACCOUNT,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.RECEIVE_MAILBOX_CREATE, ->
            _requests = _requests.set Requests.INDEX_MAILBOX,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.RECEIVE_INDEXES_COMPLETE, (res) ->
            _requests = _requests.set Requests.INDEX_MAILBOX,
                status: RequestStatus.SUCCESS, res: res
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_REQUEST, ->
            _requests = _requests.set Requests.REFRESH_MAILBOX,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_SUCCESS, (res) ->
            _requests = _requests.set Requests.REFRESH_MAILBOX,
                status: RequestStatus.SUCCESS, res: res
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_FAILURE, ({error}) ->
            _requests = _requests.set Requests.REFRESH_MAILBOX,
                status: RequestStatus.ERROR, res: {error}
            @emit 'change'


        handle ActionTypes.REFRESH_REQUEST, ->
            _requests = _requests.set Requests.REFRESH_MAILBOX,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.REFRESH_SUCCESS, ->
            _requests = _requests.set Requests.REFRESH_MAILBOX,
                status: RequestStatus.SUCCESS, res: res
            @emit 'change'


        handle ActionTypes.REFRESH_FAILURE, ({error}) ->
            _requests = _requests.set Requests.REFRESH_MAILBOX,
                status: RequestStatus.ERROR, res: {error}
            @emit 'change'


        handle ActionTypes.RECEIVE_REFRESH_STATUS, (refreshes) ->
            _refreshes = _setRefreshes refreshes
            @emit 'change'


        handle ActionTypes.RECEIVE_REFRESH_UPDATE, (refreshes) ->
            unless refreshes?.length
                _refreshes = Immutable.OrderedMap()
            else
                refreshes.forEach (refresh) ->
                    _refreshes = _refreshes.set(refresh.id, refresh).toOrderedMap()
            @emit 'change'


module.exports = new RequestsStore()
