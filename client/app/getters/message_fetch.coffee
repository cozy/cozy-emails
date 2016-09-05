Immutable = require 'immutable'

module.exports =

    getURI: (state) ->
        state.get('route').get('URIKey')

    getMessagesPerPage: (state) ->
        state.getIn ['message_fetch', 'messagesPerPage']

    getRequestStatus: (state, URIKey) ->
        state.getIn ['message_fetch', 'requests', URIKey], Immutable.Map()
