Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'

class ContactStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _query = ""

    # search results are a list of message
    _results = Immutable.OrderedMap.empty()

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.RECEIVE_RAW_CONTACT_RESULTS, (rawResults) ->
            _results = Immutable.OrderedMap.empty()
            if rawResults?
                _results = _results.withMutations (map) ->
                    rawResults.forEach (rawResult) ->
                        contact = Immutable.Map rawResult
                        map.set contact.get('address'), contact

            @emit 'change'


    ###
        Public API
    ###
    getResults: -> return _results

    getQuery: -> return _query

module.exports = new ContactStore()

