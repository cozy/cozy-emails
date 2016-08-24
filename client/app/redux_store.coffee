Immutable = require 'immutable'
{createStore} = require 'redux'
Immutable = require 'immutable'

rootReducer = require './root'
contactMapper = require '../libs/mappers/contact'
Account = require '../models/account'

initialContacts = Immutable.Map()
    .withMutations contactMapper.toMapMutator window?.contacts or []

initialAccounts = Immutable.Iterable window?.accounts or []
    .toKeyedSeq()
    # sets account ID as index
    .mapKeys (_, account) -> account.id
    # makes account object an immutable Map
    .map (rawAccount) -> Account.from rawAccount
    .toOrderedMap()

module.exports = createStore rootReducer, Immutable.Map
    accounts: initialAccounts
    contact:
        contacts: initialContacts
        results : Immutable.Map()
    settings: Immutable.Map window?.settings
