Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'


class RefreshesStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _refreshes = Immutable.OrderedMap()


    _reset = (refreshes=[]) ->
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


        handle ActionTypes.RECEIVE_REFRESH_STATUS, (refreshes) ->
            _reset refreshes


        handle ActionTypes.RECEIVE_REFRESH_UPDATE, (refresh) ->
            if refresh.length
                refresh = Immutable.Map refresh
                id = refresh.get 'objectID'
                _refreshes = _refreshes.set(id, refresh).toOrderedMap()

                @emit 'change'


        handle ActionTypes.RECEIVE_REFRESH_DELETE, (refreshID) ->
            _refreshes = _refreshes.filter (refresh) ->
                refresh.get('id') isnt refreshID
            .toOrderedMap()
            @emit 'change'


    getRefreshing: ->
        return _refreshes


module.exports = new RefreshesStore()
