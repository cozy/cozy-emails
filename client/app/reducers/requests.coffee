# TODO:
# This way to handle request is not very serious
# we have to fin a more consistant solution
# for temporary data persistence

Immutable = require 'immutable'
{ActionTypes, RequestStatus, Requests} = require '../constants/app_constants'

DEFAULT_STATE = Immutable.Map
    requests: Immutable.Map {inflight: null, queue: []}
    error: Immutable.Map()
    success: Immutable.Map()

module.exports = (state = DEFAULT_STATE, action) ->

    _addRequest = (name) ->
        requests = state.get 'requests'

        unless requests.get 'inflight'
            requests = requests.set 'inflight', name

        else
            # Add this request to requests queue
            (request = requests.get('queue') or []).push name
            requests = requests.set 'queue', request

            console.log 'QUEUE', request, requests.get('queue')

        state = state.set 'requests', requests
        console.log '(ADD)', state.get('requests').toJS()

        return state


    # Get oldest event added into queue
    # Set as state.inflight
    # Update state.queue
    _nextRequest = () ->
        requests = state.get 'requests'


        if (queue = requests.get 'queue')?.length
            request = queue.shift()

            # clean success/error context
            # not to have returns from previous request
            _removeSuccess request
            _removeError request

            console.log 'NEXT', request, queue
            requests = requests.set 'inflight', request
            requests = requests.set 'queue', queue

        else
            requests = requests.set 'inflight', null


        state = state.set 'requests', requests

        return state


    _addError = (name) ->
        error = state.get 'error'
        error = error.set name, action.value
        state = state.set 'error', error
        return state


    _removeError = (name) ->
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
            return _addRequest Requests.DISCOVER_ACCOUNT


        when ActionTypes.DISCOVER_ACCOUNT_FAILURE
            # Save error
            _addError Requests.DISCOVER_ACCOUNT

            # Handle next request
            return _nextRequest()


        when ActionTypes.DISCOVER_ACCOUNT_SUCCESS
            # Delete error
            _removeError Requests.DISCOVER_ACCOUNT

            # Handle next request
            return _nextRequest()


        when ActionTypes.CHECK_ACCOUNT_REQUEST
            return _addRequest Requests.CHECK_ACCOUNT


        when ActionTypes.CHECK_ACCOUNT_FAILURE
            # Save error
            _addError Requests.CHECK_ACCOUNT

            # Handle next request
            return _nextRequest()


        when ActionTypes.CHECK_ACCOUNT_SUCCESS
            # Delete error
            _removeError Requests.CHECK_ACCOUNT

            # Handle next request
            return _nextRequest()


        when ActionTypes.ADD_ACCOUNT_REQUEST
            return _addRequest Requests.ADD_ACCOUNT


        when ActionTypes.ADD_ACCOUNT_FAILURE
            # Save error
            _addError Requests.ADD_ACCOUNT

            # Handle next request
            return _nextRequest()


        when ActionTypes.ADD_ACCOUNT_SUCCESS
            # Delete error
            _removeError Requests.ADD_ACCOUNT

            # Handle next request
            return _nextRequest()


        when ActionTypes.RECEIVE_INDEXES_REQUEST
            return _addRequest Requests.RECEIVE_INDEXES_REQUEST


        when ActionTypes.RECEIVE_INDEXES_COMPLETE
            # Delete error
            _removeError Requests.INDEX_MAILBOX

            # Handle next request
            return _nextRequest()


        when ActionTypes.RECEIVE_ACCOUNT_CREATE
            return _addRequest Requests.ADD_ACCOUNT


        when ActionTypes.RECEIVE_MAILBOX_CREATE
            return _addRequest Requests.INDEX_MAILBOX


        when ActionTypes.CONVERSATION_FETCH_REQUEST
            return _addRequest Requests.FETCH_CONVERSATION


        when ActionTypes.CONVERSATION_FETCH_SUCCESS
            # Delete error
            _removeError Requests.FETCH_CONVERSATION

            # Handle next request
            return _nextRequest()


        when ActionTypes.CONVERSATION_FETCH_FAILURE
            # Save error
            _addError Requests.FETCH_CONVERSATION

            # Handle next request
            return _nextRequest()


        when ActionTypes.REFRESH_REQUEST
            return _addRequest Requests.REFRESH_MAILBOX


        when ActionTypes.REFRESH_SUCCESS
            # Delete error
            _removeError Requests.FETCH_CONVERSATION

            # Handle next request
            return _nextRequest()


        when ActionTypes.REFRESH_FAILURE
            # Save error
            _addError Requests.REFRESH_MAILBOX

            # Handle next request
            return _nextRequest()


    return state
