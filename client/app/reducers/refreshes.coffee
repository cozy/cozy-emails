ActionTypes = require '../constants/app_constants'
Immutable = require 'immutable'
DEFAULT_STATE = Immutable.Map()


module.exports = (state = DEFAULT_STATE, action) ->
    switch action.type

        when ActionTypes.RECEIVE_REFRESH_STATUS
            refreshes = action.value
            return new Immutable.Iterable refreshes
                .toKeyedSeq()
                .mapKeys (_, refresh) -> return refresh.objectID
                .map (refresh) -> Immutable.fromJS refresh
                .toOrderedMap()

        when ActionTypes.RECEIVE_REFRESH_UPDATE
            refreshes = action.value
            unless refreshes?.length
                return DEFAULT_STATE
            else
                for refresh in refreshes
                    state = state.set refresh.id, refresh

    return state
