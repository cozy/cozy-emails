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

    _add = (name) ->
        requests = state.get 'requests'

        unless requests.get 'inflight'
            requests = requests.set 'inflight', name
        else
            (request = requests.get('queue') or []).push name
            requests = requests.set 'queue', request

        state = state.set 'requests', requests
        console.log '(ADD)', state.get('requests').toJS()

        return state


    # Get oldest event added into queue
    # Set as state.inflight
    # Update state.queue
    _next = (name) ->
        requests = state.get 'requests'

        if (queue = requests.get 'queue')?.length
            request = queue.shift()
            requests = requests.set 'inflight', request
            requests = requests.set 'queue', queue
            console.log '(NEXT)', request
        else
            requests = requests.set 'inflight', null


        state = state.set 'requests', requests

        return state


    _addError = (name) ->
        # If request.value has changed
        # reset success storage
        # store only "last" request (consistancy)
        if (state.get('success').get name)
            success = state.get 'success'
            success = success.delete name
            state = state.set 'success', success

        error = state.get 'error'
        error = error.set name, action.value
        state = state.set 'error', error

        return state


    _addSuccess = (name) ->
        # If request has finally succeed
        # remove its name from errors
        # store only "last" request (consistancy)
        if (state.get('error').get name)
            error = state.get 'error'
            error = error.delete name
            state = state.set 'error', error

        success = state.get 'success'
        success = success.set name, action.value
        state = state.set 'success', success

        return state


    switch action.type

        # Assume that when a route 'change',
        # we won't need to keep track of
        # requests anymore, so we reset them
        when ActionTypes.ROUTE_CHANGE
            return DEFAULT_STATE


        when ActionTypes.DISCOVER_ACCOUNT_REQUEST
            return _add Requests.DISCOVER_ACCOUNT


        when ActionTypes.DISCOVER_ACCOUNT_FAILURE
            # Save error
            _addError Requests.DISCOVER_ACCOUNT

            # Handle next request
            return _next Requests.DISCOVER_ACCOUNT


        when ActionTypes.DISCOVER_ACCOUNT_SUCCESS
            # Handle next request
            return _next Requests.DISCOVER_ACCOUNT


        when ActionTypes.CHECK_ACCOUNT_REQUEST
            return _add Requests.CHECK_ACCOUNT


        when ActionTypes.CHECK_ACCOUNT_FAILURE
            # Save error
            _addError Requests.CHECK_ACCOUNT

            # Handle next request
            return _next Requests.CHECK_ACCOUNT


        when ActionTypes.CHECK_ACCOUNT_SUCCESS
            return _next Requests.CHECK_ACCOUNT


        when ActionTypes.ADD_ACCOUNT_REQUEST
            return _add Requests.ADD_ACCOUNT


        when ActionTypes.ADD_ACCOUNT_FAILURE
            # Save error
            _addError Requests.ADD_ACCOUNT

            # Handle next request
            return _next Requests.ADD_ACCOUNT


        when ActionTypes.ADD_ACCOUNT_SUCCESS
            return _next Requests.ADD_ACCOUNT


        when ActionTypes.RECEIVE_INDEXES_REQUEST
            return _add Requests.RECEIVE_INDEXES_REQUEST


        when ActionTypes.RECEIVE_INDEXES_COMPLETE
            return _next Requests.INDEX_MAILBOX


        when ActionTypes.RECEIVE_ACCOUNT_CREATE
            return _add Requests.ADD_ACCOUNT


        when ActionTypes.RECEIVE_MAILBOX_CREATE
            return _add Requests.INDEX_MAILBOX


        when ActionTypes.CONVERSATION_FETCH_REQUEST
            return _add Requests.FETCH_CONVERSATION


        when ActionTypes.CONVERSATION_FETCH_SUCCESS
            return _next Requests.FETCH_CONVERSATION


        when ActionTypes.CONVERSATION_FETCH_FAILURE
            # Save error
            _addError Requests.FETCH_CONVERSATION

            # Handle next request
            return _next Requests.FETCH_CONVERSATION


        when ActionTypes.REFRESH_REQUEST
            return _add Requests.REFRESH_MAILBOX


        when ActionTypes.REFRESH_SUCCESS
            return _next Requests.REFRESH_MAILBOX


        when ActionTypes.REFRESH_FAILURE
            # Save error
            _addError Requests.REFRESH_MAILBOX

            # Handle next request
            return _next Requests.REFRESH_MAILBOX


    return state
