_         = require 'lodash'
Immutable = require 'immutable'

{ActionTypes} = require '../constants/app_constants'

backToJSObject = (x) -> x?.toJS?() or x

shouldUpdateMessage = (current, updates) ->
    value = current?.get 'updated'
    (not value?) or (not updates.updated?) or (value < updates.updated)

Message = require '../models/message'

applyChangesOneMessage = (messages, updatedMsg) ->

    oldMessage = messages.get updatedMsg.id
    return messages unless shouldUpdateMessage(oldMessage, updatedMsg)

    now = new Date()
    attachments = updatedMsg.attachments or []
    attachments = attachments.map (file) -> Immutable.Map(file)
    attachments = Immutable.List(attachments)

    toUpdate = new Message({ # defaults
        date: now.toISOString()
        createdAt: updatedMsg.date
        flags: Immutable.List()
    })
    # argument
    .merge(updatedMsg)
    # force some values
    .remove('docType')
    .set('_displayImages', !!updatedMsg._displayImages)
    .set('attachments', attachments)
    .set('updated', now.valueOf())

    # Save reference mailbox into message informations
    if not _.isString(updatedMsg.mailboxID) or
    _.isEmpty(updatedMsg.mailboxID?.trim())
        mailboxID = oldMessage?.get('mailboxID') or
        Object.keys(updatedMsg.mailboxIDs or {})[0]
        toUpdate = toUpdate.set('mailboxID', mailboxID)

    # @TODO : mailboxIDs sould be kept as Map
    toUpdate = toUpdate.update('mailboxIDs', backToJSObject)
    # @TODO : flags sould be kept as Set
    .update('flags', backToJSObject)
    # @TODO : participants sould be kept as List
    .update('from', backToJSObject)
    .update('to', backToJSObject)
    .update('cc', backToJSObject)
    .update('bcc', backToJSObject)


    toUpdate.prettyPrint = ->
        return """
            #{updatedMsg.id} "#{updatedMsg.from[0].name}"
            "#{updatedMsg.subject}"
        """

    return messages.set toUpdate.get('id'), toUpdate


messagesReducer = (messages = Immutable.OrderedMap(), action) ->
    switch action.type
        when ActionTypes.MESSAGE_RESET_REQUEST
            return Immutable.OrderedMap()

        when ActionTypes.MESSAGE_FETCH_SUCCESS, \
             ActionTypes.CONVERSATION_FETCH_SUCCESS
            updateds = action.value.result.messages
            return updateds.reduce(applyChangesOneMessage, messages)

        when ActionTypes.RECEIVE_RAW_MESSAGES
            updateds = action.value
            return updateds.reduce(applyChangesOneMessage, messages)

        when ActionTypes.MESSAGE_FLAGS_SUCCESS, \
             ActionTypes.MESSAGE_MOVE_SUCCESS
            updateds = action.value.updated.messages
            return updateds.reduce(applyChangesOneMessage, messages)

        when ActionTypes.RECEIVE_RAW_MESSAGE, \
             ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME
            return applyChangesOneMessage(messages, action.value)

        when ActionTypes.MESSAGE_SEND_SUCCESS
            return applyChangesOneMessage(messages, action.value.message)

        when ActionTypes.REMOVE_ACCOUNT_SUCCESS
            accountID = action.value
            toKeep = (msg) -> msg.get('accountID') isnt accountID
            return messages.filter(toKeep)

        when ActionTypes.MESSAGE_TRASH_SUCCESS
            return messages.remove(action.value.target.messageID)

        when ActionTypes.RECEIVE_MESSAGE_DELETE
            return messages.remove(action.value)

        when ActionTypes.MAILBOX_EXPUNGE
            toKeep = (message) ->
                action.value isnt message.get('mailboxID') or
                not (action.value of message.get 'mailboxIDs')

            return messages.filter(toKeep)

        when ActionTypes.SETTINGS_UPDATE_REQUEST
            {messageID, displayImages} = action.value
            # Update settings into component,
            # but not definitly into settingsStore
            # @TODO: fixme what is this even supposed to do ?
            if not _.isBoolean(displayImages) and displayImages
                value = displayImages and not _.isEmpty(displayImages)
            else
                value = !!displayImages

            updated = messages.get(messageID)?.set '_displayImages', value
            return messages.set(messageID, updated)

        else
            return messages

    throw new Error('a handler didnt return ' + JSON.stringify(action))


decrementNoZero = (map, id) ->
    newlength = map.get(id) - 1
    if newlength <= 0 then return map.remove id
    else return map.set id, newlength

extractMessagesIDs = (action) ->
    if action.type is ActionTypes.MESSAGE_TRASH_SUCCESS
        return [action.value.target.messageID]
    else if action.type is ActionTypes.RECEIVE_MESSAGE_DELETE
        return [action.value]

module.exports = (state = Immutable.Map(), action) ->
    newMessages = messagesReducer(state.get('messages'), action)
    newConvLengths = state.get('conversationsLengths') or Immutable.Map()

    # FIXME: server side data
    #  - The fact that the conversation length is calculated remotely,
    #  is not clear for the developer.
    #
    #  - Most operations, like getting raw messages,
    #  don't update conversation length.
    if action.type is ActionTypes.MESSAGE_FETCH_SUCCESS
        changes = action.value.result.conversationLength
        newConvLengths = newConvLengths.merge(changes)

    if action.type is ActionTypes.CONVERSATION_FETCH_SUCCESS
        # Apply filters to messages
        # to upgrade conversationLength
        # FIXME: should be moved server side
        convID = action.value.result.messages[0].conversationID
        convLength = action.value.result.messages
        .filter (msg) -> newMessages.get(msg.id)
        .length

        # FIXME: why do we apply filter before adding to store
        # filterFunction = RouterGetter.getFilterFunction appstate
        # messages = _.filter messages, filterFunction
        newConvLengths = newConvLengths.set convID, convLength


    if action.type in [ActionTypes.MESSAGE_TRASH_SUCCESS, \
                       ActionTypes.RECEIVE_MESSAGE_DELETE]

        messageIDs = extractMessagesIDs(action)
        for messageID in messageIDs
            # Note: we use old state cause we want to get deleted messages too
            conversationID = state.getIn(['messages', messageID,
                                                            'conversationID'])
            newConvLengths = decrementNoZero newConvLengths, conversationID

    return state.merge
        messages: newMessages,
        conversationsLengths: newConvLengths
