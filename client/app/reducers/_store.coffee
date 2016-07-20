{createStore} = require 'redux'
Immutable = require 'immutable'
rootReducer = require './root'
dispatcher = require '../libs/flux/dispatcher/dispatcher'
contactMapper = require '../libs/mappers/contact'

initialContacts = Immutable.Map()
    .withMutations( contactMapper
        .toMapMutator(contactMapper.toImmutables(window?.contacts)))

reduxStore = createStore rootReducer,
    contact:
        contacts: initialContacts
        results : Immutable.Map()

reduxStoreDispatchID = dispatcher.register (action) ->
    reduxStore.dispatch(action)

module.exports = reduxStore
module.exports.dispatchToken = reduxStoreDispatchID
