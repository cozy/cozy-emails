moment      = require 'moment'
Immutable   = require 'immutable'
{MessageFlags, MessageFilter} = require '../constants/app_constants'
reduxStore = require('../reducers/_store')


module.exports =

    dispatchToken: reduxStore.dispatchToken

    getAll: ->
        reduxStore.getState().messages.messages

    getByID: (messageID) ->
        @getAll().get(messageID)


    isImagesDisplayed: (messageID) ->
        @getByID(messageID)?.get('_displayImages') or false


    # @TODO : when is this not an Immutable
    isUnread: ({flags=[], message}) ->
        if message and message not instanceof Immutable.Map
            message = Immutable.Map message
        if message?
            flags = message.get('flags') or []
            MessageFlags.SEEN not in flags
        else
            MessageFilter.UNSEEN in flags


    # @TODO : when is this not an Immutable
    isFlagged: ({flags=[], message}) ->
        if message and message not instanceof Immutable.Map
            message = Immutable.Map message
        if message?
            flags = message.get('flags') or []
            MessageFlags.FLAGGED in flags
        else
            MessageFilter.FLAGGED in flags

    # @TODO : when is this not an Immutable
    isAttached: ({flags=[], message}) ->
        if message and message not instanceof Immutable.Map
            message = Immutable.Map message
        if message?
            attachments = message.get('attachments')
            size = attachments?.size or attachments?.length
            return size? and size > 0
        else
            MessageFilter.ATTACH in flags


    isDraft: ({message}) ->
        if message and message not instanceof Immutable.Map
            message = Immutable.Map message
        if message?
            MessageFlags.DRAFT in (message.get('flags') or [])

    getConversation: (conversationID, mailboxID) ->
        @getAll().filter (message) ->
            (mailboxID of message.get 'mailboxIDs') and
            (conversationID is message.get 'conversationID')
        .sort (msg1, msg2) ->
            msg1.get('date') < msg2.get('date')
        .toArray()


    getConversationLength: (conversationID) ->
        lengths = reduxStore.getState().messages.conversationLength
        lengths.get(conversationID) or null

    # Display date as a readable string.
    # Make it shorter if compact is set to true.
    getCreatedAt: (message) ->
        return unless (date = message?.get 'createdAt')?

        today = moment()
        date  = moment date

        if date.isBefore today, 'year'
            formatter = 'DD/MM/YYYY'
        else if date.isBefore today, 'day'
            formatter = 'MMM DD'
        else
            formatter = 'HH:mm'

        return date.format formatter
