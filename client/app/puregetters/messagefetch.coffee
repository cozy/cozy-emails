Immutable = require 'immutable'

module.exports =

    getURI: (state) ->
        state.get('route').get('URIKey')

    getMessagesPerPage: (state) ->
        state.getIn ['messagefetch', 'messagesPerPage']

    getRequestStatus: (state, URIKey) ->
        state.getIn ['messagefetch', 'requests', URIKey], Immutable.Map()
