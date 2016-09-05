module.exports =

    getAll: (state) -> state.get('messages').get('messages')
    getByID: (state, messageID) -> @getAll(state).get(messageID)
    isImagesDisplayed: (state, messageID) ->
        @getByID(state, messageID)?.get('_displayImages') or false

    getConversation: (state, conversationID, mailboxID) ->
        @getAll(state).filter (message) ->
            (mailboxID of message.get 'mailboxIDs') and
            (conversationID is message.get 'conversationID')
        .sort (msg1, msg2) ->
            if msg1.get('date') < msg2.get('date') then -1
            else 1
        # .toArray()

    getConversationLength: (state, conversationID) ->
        @getConversationsLengths(state).get(conversationID) or null

    getConversationsLengths: (state) ->
        state.get('messages').get('conversationsLengths')
