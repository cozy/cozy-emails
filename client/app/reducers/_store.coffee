Immutable = require 'immutable'
{createStore} = require 'redux'
Immutable = require 'immutable'

rootReducer = require './root'
dispatcher = require '../libs/flux/dispatcher/dispatcher'
contactMapper = require '../libs/mappers/contact'
accountMapper = require '../libs/mappers/account'

initialContacts = Immutable.Map()
    .withMutations contactMapper.toMapMutator window?.contacts or []

initialAccounts = Immutable.Iterable window?.accounts or []
    .toKeyedSeq()
    # sets account ID as index
    .mapKeys (_, account) -> account.id
    # makes account object an immutable Map
    .map (rawAccount) ->
        accountMapper.formatAccount rawAccount
    .toOrderedMap()

reduxStore = createStore rootReducer, Immutable.Map
    account: Immutable.Map
        accounts: initialAccounts
        mailboxOrder: 100
    contact:
        contacts: initialContacts
        results : Immutable.Map()
    settings:
        settings: Immutable.Map window?.settings

reduxStoreDispatchID = dispatcher.register (action) ->
    reduxStore.dispatch(action)

module.exports = reduxStore
module.exports.dispatchToken = reduxStoreDispatchID
