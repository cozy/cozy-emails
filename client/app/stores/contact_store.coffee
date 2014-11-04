Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'

class ContactStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _query = ""

    # all known contacts
    _contacts = Immutable.OrderedMap.empty()
    # result of last search
    _results  = Immutable.OrderedMap.empty()

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_CONTACT_RESULTS, (rawResults) ->
            _results = Immutable.OrderedMap.empty()
            if rawResults?
                if not Array.isArray rawResults
                    rawResults = [ rawResults ]
                convert = (map) ->
                    rawResults.forEach (rawResult) ->
                        rawResult.datapoints.forEach (point) ->
                            if point.name is 'email'
                                rawResult.address = point.value
                            if point.name is 'avatar'
                                rawResult.avatar = point.value
                        contact = Immutable.Map rawResult
                        map.set contact.get('address'), contact
                _results  = _results.withMutations convert
                _contacts = _contacts.withMutations convert

            @emit 'change'


    ###
        Public API
    ###
    getResults: -> return _results

    getQuery: -> return _query

    getAvatar: (address) ->
        return _contacts.get(address)?.get 'avatar'

module.exports = new ContactStore()

