Immutable = require 'immutable'

Store = require '../libs/flux/store/store'
MessageStore = require './message_store'

{ActionTypes} = require '../constants/app_constants'

NUMBER_BY_PAGE = 10

class SearchStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _fetching = 0

    _currentSearch = ''
    _currentSearchPage = 0
    _currentSearchMore = false
    _currentSearchAccountID = 'all'
    _currentSearchResults = Immutable.Set()
    _currentSearchAccounts = Immutable.Map()

    resetSearch = ->
        _currentSearch = ''
        _currentSearchResults = _currentSearchResults.clear()
        _currentSearchAccounts = Immutable.Map()
        _currentSearchPage = 0
        _currentSearchMore = false

    resetSearch()

    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.QUERY_PARAMETER_CHANGED, ->
            resetSearch()
            @emit 'change'

        handle ActionTypes.SEARCH_PARAMETER_CHANGED, ({search, accountID}) ->
            if search isnt _currentSearch or
            accountID isnt _currentSearchAccountID
                resetSearch()

            _currentSearch = search
            _currentSearchAccountID = accountID

            @emit 'change'

        handle ActionTypes.SEARCH_REQUEST, (search) ->
            _fetching++
            _currentSearchPage++
            @emit 'change'

        handle ActionTypes.SEARCH_FAILURE, ({error}) ->
            _fetching--
            _currentSearchPage--
            _currentSearchResults = _currentSearchResults.clear()
            @emit 'change'

        handle ActionTypes.SEARCH_SUCCESS, ({searchResults}) ->
            _fetching--
            accounts = searchResults.accounts
            ids = searchResults.rows.map (message) -> message._id
            _currentSearchMore = ids.length is NUMBER_BY_PAGE
            _currentSearchResults = _currentSearchResults.union ids
            _currentSearchAccounts = _currentSearchAccounts.merge accounts
            @emit 'change'


    getCurrentSearch: ->
        return _currentSearch

    getCurrentSearchKey: ->
        return encodeURIComponent _currentSearch

    getCurrentSearchAccountID: ->
        return _currentSearchAccountID

    getCurrentSearchResults: ->
        _currentSearchResults
        .toOrderedMap()
        .mapEntries ([id]) ->
            [id, MessageStore.getByID id]
        .filter (message) ->
            message isnt null

    hasMoreSearch: ->
        _currentSearchMore

    getNextSearchUrl: () ->
        url = "search?search=#{@getCurrentSearchKey()}"
        url += "&pageSize=#{NUMBER_BY_PAGE}"
        if _currentSearchPage
            url += "&page=#{_currentSearchPage}"
        if _currentSearchAccountID isnt 'all'
            url += "&accountID=#{_currentSearchAccountID}"

        return url


module.exports = self = new SearchStore()
