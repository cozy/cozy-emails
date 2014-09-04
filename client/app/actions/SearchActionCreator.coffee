AppDispatcher = require '../AppDispatcher'
{ActionTypes} = require '../constants/AppConstants'

module.exports = SearchActionCreator =

    setQuery: (query) ->
        AppDispatcher.handleViewAction
            type: ActionTypes.SET_SEARCH_QUERY
            value: query

    receiveRawSearchResults: (results) ->

        # first clear the previous results
        SearchActionCreator.clearSearch false

        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_RAW_SEARCH_RESULTS
            value: results

    clearSearch: (clearQuery = true) ->
        if clearQuery then SearchActionCreator.setQuery ""

        AppDispatcher.handleViewAction
            type: ActionTypes.CLEAR_SEARCH_RESULTS
            value: null

