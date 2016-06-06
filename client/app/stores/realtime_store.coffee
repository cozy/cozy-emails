Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'


class RealtimeStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _refreshes = Immutable.OrderedMap()
    _isIndexing = false


    _reset = (refreshes=[]) ->
        # Display IndexingView
        # as defaultView
        _isIndexing = true

        _refreshes = Immutable.Iterable refreshes
        .toKeyedSeq()
        .mapKeys (_, refresh) -> return refresh.objectID
        .map (refresh) -> Immutable.fromJS refresh
        .toOrderedMap()


    _update = (refresh) ->
        if refresh.length
            refresh = Immutable.Map refresh
            id = refresh.get 'objectID'
            _refreshes = _refreshes.set(id, refresh).toOrderedMap()


    _reset window.refreshes


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_INDEXES_REQUEST, ->
            _isIndexing = true
            @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_REQUEST, ->
            _isIndexing = true
            @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_FAILURE, ->
            _isIndexing = false
            @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_SUCCESS, ->
            _isIndexing = false
            @emit 'change'


        handle ActionTypes.RECEIVE_ACCOUNT_CREATE, ->
            _isIndexing = true
            @emit 'change'


        handle ActionTypes.RECEIVE_ACCOUNT_UPDATE, ->
            _isIndexing = true
            @emit 'change'


        handle ActionTypes.RECEIVE_MAILBOX_CREATE, ->
            _isIndexing = true
            @emit 'change'


        handle ActionTypes.RECEIVE_MAILBOX_UPDATE, ->
            _isIndexing = true
            @emit 'change'


        handle ActionTypes.RECEIVE_INDEXES_COMPLETE, ->
            _isIndexing = false
            @emit 'change'


        handle ActionTypes.RECEIVE_REFRESH_STATUS, (refreshes) ->
            _reset refreshes
            @emit 'change'


        handle ActionTypes.RECEIVE_REFRESH_UPDATE, (refreshes) ->
            unless refreshes?.length
                _refreshes = Immutable.OrderedMap()
            else
                refreshes.forEach (refresh) ->
                    _refreshes = _refreshes.set(refresh.id, refresh).toOrderedMap()
            @emit 'change'


        handle ActionTypes.RECEIVE_REFRESH_DELETE, (refreshID) ->
            _refreshes = _refreshes.filter (refresh) ->
                refresh.get('id') isnt refreshID
            .toOrderedMap()
            @emit 'change'


    isRefreshError: ->
        _refreshes.get('errors')?.length


    isRefreshing: ->
        0 isnt _refreshes.size


    isIndexing: ->
        _isIndexing

module.exports = new RealtimeStore()
