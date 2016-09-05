combineReducers = (reducers) ->
    keys = Object.keys(reducers)
    return (state, action) ->
        # console.log("DISPATCH", action.type, action.value)
        return state.withMutations (mutableState) ->
            for name in keys
                stateSlice = state.get(name)
                newstateSlice = reducers[name](stateSlice, action, state)
                if newstateSlice isnt stateSlice
                    mutableState.set(name, newstateSlice)
            undefined # prevent coffee comprehension


module.exports = combineReducers({
    accounts        : require './account'
    modal           : require './modal'
    route           : require './route'
    requests        : require './requests'
    refreshes       : require './refreshes'
    messagefetch    : require './message_fetch'
    selection       : require './selection'
    notifications   : require './notifications'
    messages        : require './message'
    contacts        : require './contact'
    contact_search   : require './contact_search'
    layout          : require './layout'
    settings        : require './settings'
})
