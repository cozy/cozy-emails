Immutable = require 'immutable'
{ActionTypes} = require '../constants/app_constants'

combineReducers = (reducers) ->
    keys = Object.keys(reducers)
    return (state, action) ->
        console.log("DISPATCH", action.type, action.value)

        state = Immutable.Map() if action.type is ActionTypes.RESET_FOR_TESTS

        return state.withMutations (mutableState) ->
            for name in keys
                stateSlice = state.get(name)
                newstateSlice = reducers[name](stateSlice, action, state)
                if newstateSlice isnt stateSlice
                    mutableState.set(name, newstateSlice)
            undefined # prevent coffee comprehension


module.exports = combineReducers({
    accounts:      require './account'
    modal:        require './modal'
    route:        require './route'
    requests:     require './requests'
    refreshes:    require './refreshes'
    messagefetch: require './messagefetch'
    selection:    require './selection'
    notifications: require './notifications'
    messages:     require './message'
    contacts:     require './contact'
    contactsearch: require './contactsearch'
    layout:       require './layout'
    settings:     require './settings'
})
