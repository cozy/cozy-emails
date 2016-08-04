reduxStore = require('../reducers/_store')

pure = require('../puregetters/messages')

module.exports =

    dispatchToken: reduxStore.dispatchToken

    getAll: ->
        pure.getAll(reduxStore.getState())

    getByID: (messageID) ->
        pure.getByID(reduxStore.getState(), messageID)

    isImagesDisplayed: (messageID) ->
        pure.isImagesDisplayed(reduxStore.getState(), messageID)

    getConversation: (conversationID, mailboxID) ->
        pure.getConversation(reduxStore.getState(), conversationID, mailboxID)

    getConversationLength: (conversationID) ->
        pure.getConversationLength(reduxStore.getState(), conversationID)
