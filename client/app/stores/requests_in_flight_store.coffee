Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes, Requests} = require '../constants/app_constants'


class RequestsInFlightStore extends Store

    _requests = new Immutable.Map
        "#{Requests.DISCOVER}": false


    getRequests: ->
        return _requests


    __bindHandlers: (handle) ->

        handle ActionTypes.DISCOVER_REQUEST, ({domain}) ->
            _requests = _requests.set Requests.DISCOVER,  true
            @emit 'change'


        handle ActionTypes.DISCOVER_FAILURE, ({error, domain}) ->
            _requests = _requests.set Requests.DISCOVER, error
            @emit 'change'


        handle ActionTypes.DISCOVER_SUCCESS, ({domain, provider}) ->
            _requests = _requests.set Requests.DISCOVER, provider
            @emit 'change'


module.exports = new RequestsInFlightStore()
