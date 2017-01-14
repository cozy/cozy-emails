###

RequestsStore
=============

Handles current requests performed in background to let components aware of
their current status.

TODO: when migrating to a stateless server app, all requests status should be
handled by realtime stack and this store should be deprecated.

###

Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes, Requests, RequestStatus} = require '../constants/app_constants'


_reset = ->
    new Immutable.Map
        "#{Requests.DISCOVER_ACCOUNT}": status: null, res: undefined
        "#{Requests.CHECK_ACCOUNT}":    status: null, res: undefined
        "#{Requests.ADD_ACCOUNT}":      status: null, res: undefined


class RequestsStore extends Store

    _requests = _reset()


    get: (req) ->
        return _requests.get req


    __bindHandlers: (handle) ->

        # Assume that when a route 'change', we won't need to keep track of
        # requests anymore, so we reset them
        handle ActionTypes.ROUTE_CHANGE, ->
            _requests = _reset()
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


module.exports = new RequestsStore()
