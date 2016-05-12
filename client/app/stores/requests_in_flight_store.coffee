Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes, Requests, RequestStatus} = require '../constants/app_constants'


class RequestsInFlightStore extends Store

    _requests = new Immutable.Map
        "#{Requests.DISCOVER_ACCOUNT}": status: null, res: undefined
        "#{Requests.CHECK_ACCOUNT}":    status: null, res: undefined


    getRequests: ->
        return _requests


    __bindHandlers: (handle) ->

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


module.exports = new RequestsInFlightStore()
