Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'

ApiUtils = require '../utils/api_utils'


refreshesToImmutable = (refreshes) ->
    Immutable.Iterable refreshes
    # sets objectID as index
    .toKeyedSeq()
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
            return unless refresh.length
            refresh = Immutable.Map refresh
            id = refresh.get('objectID')
            _refreshes = _refreshes.set(id, refresh).toOrderedMap()
            @emit 'change'

        handle ActionTypes.RECEIVE_REFRESH_DELETE, (refreshID) ->
            _refreshes = _refreshes.filter (refresh) ->
                refresh.get('id') isnt refreshID
            .toOrderedMap()
            @emit 'change'

        # handle ActionTypes.RECEIVE_REFRESH_NOTIF, (data) ->
        #     console.log 'PLOP', t('notif new title'), body: data.message
        #     # ApiUtils.notify t('notif new title'), body: data.message


    getRefreshing: ->
        return _refreshes


module.exports = new RefreshesStore()
