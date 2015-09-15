Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'


refreshesToImmutable = (refreshes) ->
    Immutable.Sequence refreshes
    # sets objectID as index
    .mapKeys (_, refresh) -> return refresh.objectID
    .map (refresh) -> Immutable.fromJS refresh
    .toOrderedMap()


class RefreshesStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###
    _refreshes = refreshesToImmutable window.refreshes or []


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->


        handle ActionTypes.RECEIVE_REFRESH_STATUS, (refreshes) ->
            _refreshes = refreshesToImmutable refreshes

        handle ActionTypes.RECEIVE_REFRESH_UPDATE, (refresh) ->
            refresh = Immutable.Map refresh
            id = refresh.get('objectID')
            _refreshes = _refreshes.set(id, refresh).toOrderedMap()
            @emit 'change'

        handle ActionTypes.RECEIVE_REFRESH_DELETE, (refreshID) ->
            _refreshes = _refreshes.filter (refresh) ->
                refresh.get('id') isnt refreshID
            .toOrderedMap()
            @emit 'change'

        handle ActionTypes.RECEIVE_REFRESH_NOTIF, (data) ->
            @emit 'notify', t('notif new title'), body: data.message


    getRefreshing: ->
        return _refreshes


module.exports = new RefreshesStore()

