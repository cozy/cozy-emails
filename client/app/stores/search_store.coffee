Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'


class SearchStore extends Store

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

        handle ActionTypes.RECEIVE_RAW_SEARCH_RESULTS, (rawResults) ->
            if rawResults?
                _results = _results.withMutations (map) ->
                    rawResults.forEach (rawResult) ->
                        message = Immutable.Map rawResult
                        map.set message.get('id'), message
            else
                _results = Immutable.OrderedMap.empty()

            @emit 'change'

        handle ActionTypes.CLEAR_SEARCH_RESULTS, ->
            _results = Immutable.OrderedMap.empty()
            @emit 'change'

        handle ActionTypes.SET_SEARCH_QUERY, (query) ->
            _query = query
            @emit 'change'


    ###
        Public API
    ###
    getResults: ->
        return _results

    getQuery: ->
        return _query


module.exports = new SearchStore()
