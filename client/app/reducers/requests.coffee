Immutable = require 'immutable'
{ActionTypes, RequestStatus, Requests} = require '../constants/app_constants'

DEFAULT_STATE = Immutable.Map
    "#{Requests.DISCOVER_ACCOUNT}":     status: null, res: undefined
    "#{Requests.CHECK_ACCOUNT}":        status: null, res: undefined
    "#{Requests.ADD_ACCOUNT}":          status: null, res: undefined
    "#{Requests.INDEX_MAILBOX}":        status: null, res: undefined
    "#{Requests.REFRESH_MAILBOX}":      status: null, res: undefined
    "#{Requests.FETCH_CONVERSATION}":   status: null, res: undefined

module.exports = (state = DEFAULT_STATE, action) ->
    switch action.type

        # Assume that when a route 'change',
        # we won't need to keep track of
        # requests anymore, so we reset them
        when ActionTypes.ROUTE_CHANGE
            return DEFAULT_STATE

        when ActionTypes.DISCOVER_ACCOUNT_REQUEST
            return state.set Requests.DISCOVER_ACCOUNT,
                status: RequestStatus.INFLIGHT, res: undefined

        when ActionTypes.DISCOVER_ACCOUNT_FAILURE
            {error} = action.value
            return state.set Requests.DISCOVER_ACCOUNT,
                status: RequestStatus.ERROR, res: error

        when ActionTypes.DISCOVER_ACCOUNT_SUCCESS
            {provider} = action.value
            return state.set Requests.DISCOVER_ACCOUNT,
                status: RequestStatus.SUCCESS, res: provider

        when ActionTypes.CHECK_ACCOUNT_REQUEST
            return state.set Requests.CHECK_ACCOUNT,
                status: RequestStatus.INFLIGHT, res: undefined

        when ActionTypes.CHECK_ACCOUNT_FAILURE
            {error, oauth} = action.value
            return state.set Requests.CHECK_ACCOUNT,
                status: RequestStatus.ERROR, res: {error, oauth}

        when ActionTypes.CHECK_ACCOUNT_SUCCESS
            {account} = action.value
            return state.set Requests.CHECK_ACCOUNT,
                status: RequestStatus.SUCCESS, res: account

        when ActionTypes.ADD_ACCOUNT_REQUEST
            return state.set Requests.ADD_ACCOUNT,
                status: RequestStatus.INFLIGHT, res: undefined

        when ActionTypes.ADD_ACCOUNT_FAILURE
            {error} = action.value
            return state.set Requests.ADD_ACCOUNT,
                status: RequestStatus.ERROR, res: {error}

        when ActionTypes.ADD_ACCOUNT_SUCCESS
            res = action.value
            return state.set Requests.ADD_ACCOUNT,
                status: RequestStatus.SUCCESS, res: res

        when ActionTypes.RECEIVE_INDEXES_REQUEST
            mailbox = action.value
            return state.set Requests.INDEX_MAILBOX,
                status: RequestStatus.INFLIGHT, res: mailbox

        when ActionTypes.RECEIVE_INDEXES_COMPLETE
            return state.set Requests.INDEX_MAILBOX,
                status: RequestStatus.SUCCESS

        when ActionTypes.RECEIVE_ACCOUNT_CREATE
            return state.set Requests.ADD_ACCOUNT,
                status: RequestStatus.INFLIGHT, res: undefined

        when ActionTypes.RECEIVE_MAILBOX_CREATE
            return state.set Requests.INDEX_MAILBOX,
                status: RequestStatus.INFLIGHT, res: undefined

        when ActionTypes.CONVERSATION_FETCH_REQUEST
            res = action.value
            return state.set Requests.FETCH_CONVERSATION,
                status: RequestStatus.INFLIGHT, res: undefined

        when ActionTypes.CONVERSATION_FETCH_SUCCESS
            res = action.value
            return state.set Requests.FETCH_CONVERSATION,
                status: RequestStatus.SUCCESS, res: {res}

        when ActionTypes.CONVERSATION_FETCH_FAILURE
            {error} = action.value
            return state.set Requests.FETCH_CONVERSATION,
                status: RequestStatus.ERROR, res: {error}

        when ActionTypes.REFRESH_REQUEST
            return state.set Requests.REFRESH_MAILBOX,
                status: RequestStatus.INFLIGHT, res: undefined

        when ActionTypes.REFRESH_SUCCESS
            res = action.value
            return state.set Requests.REFRESH_MAILBOX,
                status: RequestStatus.SUCCESS, res: res

        when ActionTypes.REFRESH_FAILURE
            {error} = action.value
            return state.set Requests.REFRESH_MAILBOX,
                status: RequestStatus.ERROR, res: {error}

    return state
