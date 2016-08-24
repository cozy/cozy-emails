Immutable = require 'immutable'
{ActionTypes} = require '../constants/app_constants'
RouterGetter = require '../getters/router'
{MSGBYPAGE} = require '../../../server/utils/constants'

MessageFetch = Immutable.Record
    isComplete    : false
    isLoading     : false
    lastFetchOldest: null

DEFAULT_STATE = Immutable.Map
    messagesPerPage: MSGBYPAGE
    requests: Immutable.Map()

findOldest = (msg1, msg2) ->
    return msg2 unless msg1
    if msg1.date > msg2.date then msg1 else msg2

getRequestObject = (state, URIKey) ->
    return state.getIn(['requests', URIKey], new MessageFetch())

setOnRequest = (state, URIKey, field, value) ->
    messageFetch = getRequestObject(state, URIKey).set(field, value)
    return state.set('requests', URIKey, messageFetch)

module.exports = (state = DEFAULT_STATE, action, appstate) ->
    switch action.type

        when ActionTypes.ROUTE_CHANGE
            messagesPerPage = action.value.messagesPerPage
            if messagesPerPage
                return state.set('messagesPerPage', messagesPerPage)

        when ActionTypes.MESSAGE_FETCH_REQUEST
            URIKey = RouterGetter.getURI(appstate)
            if state.getIn(['requests', URIKey, 'isLoading'], false)
                console.log "WARNING : parallel messages fetch queries"
            return setOnRequest(state, URIKey, 'isLoading', true)

        when ActionTypes.MESSAGE_FETCH_FAILURE
            URIKey = RouterGetter.getURI(appstate)
            return setOnRequest(state, URIKey, 'isLoading', false)

        when ActionTypes.MESSAGE_FETCH_SUCCESS
            {result} = action.value
            URIKey = RouterGetter.getURI(appstate)
            state = setOnRequest(state, URIKey, 'isLoading', false)

            pageAfter = result.messages.reduce(findOldest, null)?.date
            state = setOnRequest(state, URIKey, 'lastFetchOldest', pageAfter)

            if result.messages.length is 0
                state = setOnRequest(state, URIKey, 'isComplete', true)

    return state
