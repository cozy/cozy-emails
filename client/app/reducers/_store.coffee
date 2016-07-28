{createStore} = require 'redux'
rootReducer = require './root'
dispatcher = require '../libs/flux/dispatcher/dispatcher'

reduxStore = createStore(rootReducer, {})

reduxStoreDispatchID = dispatcher.register (action) ->
    reduxStore.dispatch(action)

module.exports = reduxStore
module.exports.dispatchToken = reduxStoreDispatchID
