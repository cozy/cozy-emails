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
AppDispatcher = require '../libs/flux/dispatcher/dispatcher'

{ActionTypes
AccountActions
Requests
RequestStatus} = require '../constants/app_constants'

MessageStore  = require '../stores/message_store'

_setRefreshes = (refreshes=[]) ->
    new Immutable.Iterable refreshes
        .toKeyedSeq()
        .mapKeys (_, refresh) -> return refresh.objectID
        .map (refresh) -> Immutable.fromJS refresh
        .toOrderedMap()

_setRequests = ->
    new Immutable.Map
        "#{Requests.DISCOVER_ACCOUNT}":     status: null, res: undefined
        "#{Requests.CHECK_ACCOUNT}":        status: null, res: undefined
        "#{Requests.ADD_ACCOUNT}":          status: null, res: undefined
        "#{Requests.INDEX_MAILBOX}":        status: null, res: undefined
        "#{Requests.REFRESH_MAILBOX}":      status: null, res: undefined
        "#{Requests.FETCH_CONVERSATION}":   status: null, res: undefined


class RequestsStore extends Store

    _requests = _setRequests()

    _refreshes = _setRefreshes window?.refreshes


    ###
    Private methods
    =============
    ###
    _isLoading =  (req) ->
        # TODO: vérifier dans le cas de l'indexation
        # le accountID concerné
        RequestStatus.INFLIGHT is _requests.get(req)?.status


    ###
    Public methods
    =============
    ###
    get: (req) ->
        _requests.get req


    isRefreshError: ->
        _refreshes.get('errors')?.length


    isRefreshing: ->
        0 isnt _refreshes.size or _isLoading Requests.REFRESH_MAILBOX


    isIndexing: (accountID) ->
        actions = [Requests.INDEX_MAILBOX, Requests.ADD_ACCOUNT]
        _requests.find (request, name) ->
            if name in actions and _isLoading name
                return request.res?.accountID is accountID


    isConversationLoading: ->
        _isLoading Requests.FETCH_CONVERSATION


    __bindHandlers: (handle) ->

        # Assume that when a route 'change',
        # we won't need to keep track of
        # requests anymore, so we reset them
        handle ActionTypes.ROUTE_CHANGE, ->
            _requests ?= _setRequests()
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


        handle ActionTypes.RECEIVE_INDEXES_REQUEST, (mailbox) ->
            _requests = _requests.set Requests.INDEX_MAILBOX,
                status: RequestStatus.INFLIGHT, res: mailbox
            @emit 'change'


        handle ActionTypes.RECEIVE_INDEXES_COMPLETE, ->
            _requests = _requests.set Requests.INDEX_MAILBOX,
                status: RequestStatus.SUCCESS
            @emit 'change'


        handle ActionTypes.RECEIVE_ACCOUNT_CREATE, ->
            _requests = _requests.set Requests.ADD_ACCOUNT,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.RECEIVE_MAILBOX_CREATE, ->
            _requests = _requests.set Requests.INDEX_MAILBOX,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_REQUEST, (res) ->
            _requests = _requests.set Requests.FETCH_CONVERSATION,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_SUCCESS, (res) ->
            _requests = _requests.set Requests.FETCH_CONVERSATION,
                status: RequestStatus.SUCCESS, res: {res}
            @emit 'change'


        handle ActionTypes.MESSAGE_FETCH_FAILURE, ({error, conversationID}) ->
            _requests = _requests.set Requests.FETCH_CONVERSATION,
                status: RequestStatus.ERROR, res: {error}
            @emit 'change'


        handle ActionTypes.REFRESH_REQUEST, ->
            _requests = _requests.set Requests.REFRESH_MAILBOX,
                status: RequestStatus.INFLIGHT, res: undefined
            @emit 'change'


        handle ActionTypes.REFRESH_SUCCESS, (res) ->
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
