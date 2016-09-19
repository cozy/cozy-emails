# RequestReducer
#
# handle Request as a queue of events
# each event is define with its name
#
# Inflight is the name of current executed event
# Requests is an array of events name
# Success is an array of events name
# Errors is an array of events name
#
# It doesnt store Error/Success value
# that doesnt seem important
# to handle Error/Success Component
#
# Name is enough to specify the kind of error
# ie. discover, check for Account

Immutable = require 'immutable'
{ActionTypes, Requests} = require '../constants/app_constants'

DEFAULT_STATE = Immutable.Map
    requests: Immutable.Map {inflight: null, queue: []}
    error: Immutable.Map()
    success: Immutable.Map()


RequestReducer = (state = DEFAULT_STATE, action) ->



    _saveRequest = (name) ->
        requests = state.get 'requests'
        queue = requests.get 'queue'

        # Remove Old
        if (index = queue.indexOf name) > -1
            queue = queue.splice index, 1

        # Update Queue
        queue = queue.push name

        return state


    # Get oldest event added into queue
    # Set as state.inflight
    # Update state.queue
    _execRequest = () ->
        requests = state.get('requests')
        queue = requests.get('queue') or []
        inflight = requests.get('inflight')

        inflight = queue.shift() or null
        requests = requests.set 'inflight', inflight
        state = state.set 'requests', requests

        return state


    _saveError = (name) ->
        error = state.get 'error'
        error = error.set name, action.value
        state = state.set 'error', error
        return state


    _deleteError = (name) ->
        error = state.get 'error'
        error = error.remove name
        state = state.set 'error', error
        return state


    _addSuccess = (name) ->
        success = state.get 'success'
        success = success.set name, action.value
        state = state.set 'success', success
        return state


    _removeSuccess = (name) ->
        success = state.get 'success'
        success = success.remove name
        state = state.set 'success', success
        return state


    switch action.type

        # Assume that when a route 'change',
        # we won't need to keep track of
        # requests anymore, so we reset them
        when ActionTypes.ROUTE_CHANGE
            return DEFAULT_STATE


        when ActionTypes.DISCOVER_ACCOUNT_REQUEST
            # Save Request
            _saveRequest Requests.DISCOVER_ACCOUNT

            # Handle next request
            return _execRequest()


        when ActionTypes.DISCOVER_ACCOUNT_FAILURE
            # Save error
            _saveError Requests.DISCOVER_ACCOUNT

            # Handle current request
            return _execRequest()


        when ActionTypes.DISCOVER_ACCOUNT_SUCCESS
            # Delete error
            _deleteError Requests.DISCOVER_ACCOUNT

            # Handle next request
            return _execRequest()


        when ActionTypes.CHECK_ACCOUNT_REQUEST
            # Save Request
            _saveRequest Requests.CHECK_ACCOUNT

            # Handle current request
            return _execRequest()


        when ActionTypes.CHECK_ACCOUNT_FAILURE
            # Save error
            _saveError Requests.CHECK_ACCOUNT

            # Handle next request
            return _execRequest()


        when ActionTypes.CHECK_ACCOUNT_SUCCESS
            # Delete error
            _deleteError Requests.CHECK_ACCOUNT

            # Handle next request
            return _execRequest()


        when ActionTypes.ADD_ACCOUNT_REQUEST
            # Save Request
            _saveRequest Requests.ADD_ACCOUNT

            # Handle current request
            return _execRequest()


        when ActionTypes.ADD_ACCOUNT_FAILURE
            # Save error
            _saveError Requests.ADD_ACCOUNT

            # Handle next request
            return _execRequest()


        when ActionTypes.ADD_ACCOUNT_SUCCESS
            # Delete error
            _deleteError Requests.ADD_ACCOUNT

            # Handle next request
            return _execRequest()


        when ActionTypes.RECEIVE_INDEXES_REQUEST
            # Save Request
            _saveRequest Requests.INDEX_MAILBOX

            # Handle next request
            return _execRequest()


        when ActionTypes.RECEIVE_INDEXES_COMPLETE
            # Delete error
            _deleteError Requests.INDEX_MAILBOX

            # Handle next request
            return _execRequest()


        when ActionTypes.RECEIVE_ACCOUNT_CREATE
            # Save Request
            _saveRequest Requests.ADD_ACCOUNT

            # Handle current request
            return _execRequest()


        when ActionTypes.RECEIVE_MAILBOX_CREATE
            # Save Request
            _saveRequest Requests.INDEX_MAILBOX

            # Handle current request
            return _execRequest()


        when ActionTypes.CONVERSATION_FETCH_REQUEST
            # Save Request
            _saveRequest Requests.FETCH_CONVERSATION

            # Handle current request
            return _execRequest()


        when ActionTypes.CONVERSATION_FETCH_SUCCESS
            # Delete error
            _deleteError Requests.FETCH_CONVERSATION

            # Handle next request
            return _execRequest()


        when ActionTypes.CONVERSATION_FETCH_FAILURE
            # Save error
            _saveError Requests.FETCH_CONVERSATION

            # Handle next request
            return _execRequest()


        when ActionTypes.REFRESH_REQUEST
            # Save Request
            _saveRequest Requests.REFRESH_MAILBOX

            # Handle current request
            return _execRequest()


        when ActionTypes.REFRESH_SUCCESS
            # Delete error
            _deleteError Requests.REFRESH_MAILBOX

            # Handle next request
            return _execRequest()


        when ActionTypes.REFRESH_FAILURE
            # Save error
            _saveError Requests.REFRESH_MAILBOX

            # Handle next request
            return _execRequest()


    return state


module.exports = RequestReducer
