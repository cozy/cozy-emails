AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'
RouterStore = require '../stores/router_store'

Immutable = require 'immutable'
{sortByDate} = require '../utils/misc'
{MessageFilter, MessageFlags, MailboxFlags} = require '../constants/app_constants'

_ = require 'lodash'

class RouteGetter

    _currentMessages = null

    getNextURL: ->
        RouterStore.getNextURL()

    getURL: (params) ->
        RouterStore.getURL params

    getAction: ->
        RouterStore.getAction()

    getQueryParams: ->
        RouterStore.getQueryParams()

    getFilter: ->
        RouterStore.getFilter()

    isLoading: ->
        MessageStore.isFetching()

    ###*
    * Get older conversation displayed before current
    *
    * @param {Function}  transform
    *
    * @return {List}
    ###
    getPreviousConversation: (param={}) ->
        transform = (index) -> ++index
        @getMessage _.extend param, {transform}

    ###*
    * Get earlier conversation displayed after current
    *
    * @param {Function}  transform
    *
    * @return {List}
    ###
    getNextConversation: (params={}) ->
        transform = (index) -> --index
        @getMessage _.extend params, {transform}


    isFlags: (name) ->
        flags = @getFilter()?.flags or []
        MessageFilter[name] is flags or MessageFilter[name] in flags

    getMessagesToDisplay: (mailboxID) ->
        # Get Messages from Mailbox
        mailboxID ?= @getMailboxID()
        messages = MessageStore.getCurrentConversations mailboxID


        # Apply Filters
        # We dont filter for type from and dest because it is
        # complicated by collation and name vs address.
        # Instead we clear the message, see QUERY_PARAMETER_CHANGED handler.
        filter = @getFilter()
        if not _.isEmpty(filter.flags)
            messages = messages.filter (message, index) =>
                value = true

                if @isFlags 'FLAGGED', filter.flags
                    unless (value = MessageFlags.FLAGGED in message.get 'flags')
                        return false

                if @isFlags 'ATTACH', filter.flags
                    unless (value = message.get('attachments').size > 0)
                        return false

                if @isFlags 'UNSEEN', filter.flags
                    unless (value = MessageFlags.SEEN not in message.get 'flags')
                        return false
                value

        # FIXME : use params ASC et DESC into URL
        messages = messages.sort sortByDate filter.order

        _currentMessages = messages.toOrderedMap()
        return _currentMessages


    ###*
    * Get Conversation
    *
    * If none parameters    return current conversation
    * @param.transform      return the list index needed
    * @param.type="message" return the closest message
    *                       instead of conversation
    *
    * @param {String}   type
    * @param {Function} transform
    *
    * @return {List}
    ###
    getMessage: (param={}) ->
        # FIXME : vérifier les params rentrant
        # ne passer que par messageID si possible
        {messageID, conversationID, messages, conversationIDs} = param

        # console.log 'getMessage', conversationID, conversationIDs
        messages ?= _currentMessages

        # In this case, we just want
        # next/previous message from a selection
        # then remove selected messages from the list
        if conversationIDs?
            conversationID = conversationIDs[0]
            messages = messages
                .filter (message) ->
                    id = message.get 'conversationID'
                    index = conversationIDs.indexOf id
                    return index is -1
                .toList()

        unless conversationID
            messageID ?= MessageStore.getCurrentID()
            message = MessageStore.getByID messageID
            conversationID = message?.get 'conversationID'

        # If no specific action is precised
        # return contextual conversations
        unless _.isFunction param.transform
            return MessageStore.getByID messageID

        getMessage = =>
            _getMessage = (index) ->
                index0 = param.transform index
                messages?.get(index0)

            # Get next Conversation not next message
            # `messages` is the list of all messages not conversations
            # TODO : regroup message by its conversationID
            # and use messages.find instead with a simple test
            # FIXME : inconsistency between the 2 results, see why?
            index0 = messages.toArray().findIndex (message, index) ->
                isSameMessage = conversationID is message?.get 'conversationID'
                isNextSameConversation = _getMessage(index)?.get('conversationID') isnt conversationID
                return isSameMessage and isNextSameConversation

            _getMessage(index0)

        # Change Conversation
        return Immutable.Map getMessage()

    getConversationLength: (messageID) ->
        messageID ?= MessageStore.getCurrentID()
        message = _currentMessages.find (message) ->
            message.get('id') is messageID
        # console.log message.get('messageIDs').toJS()
        message.get('messageIDs')?.size


    getConversationMessages: (messageID) ->
        messageID ?= MessageStore.getCurrentID()
        messageIDs = MessageStore.getByID(messageID)?.get('messageIDs')
        return messageIDs?.map (messageID) ->
            MessageStore.getByID messageID


    getCurrentMessageID: ->
        MessageStore.getCurrentID()

    isCurrentMessage: (messageID) ->
        messageID is @getCurrentMessageID()

    getCurrentMailbox: (id) ->
        AccountStore.getSelectedMailbox id

    getAccountID: ->
        AccountStore.getSelectedOrDefault()?.get 'id'

    getMailboxID: ->
        @getCurrentMailbox()?.get 'id'

    getLogin: ->
        @getCurrentMailbox()?.get 'login'

    getMailboxes: ->
        AccountStore.getSelectedMailboxes()

    getTags: (message) ->
        mailboxID = @getMailboxID()
        mailboxesIDs = Object.keys message.get 'mailboxIDs'
        result = mailboxesIDs.map (id) =>
            if (mailbox = @getCurrentMailbox id)
                isGlobal = MailboxFlags.ALL in mailbox.get 'attribs'
                isEqual = mailboxID is id
                unless (isEqual or isGlobal)
                    return mailbox?.get 'label'
        _.uniq _.compact result

    getEmptyMessage: ->
        filter = @getFilter()
        if @isFlags 'UNSEEN', filter.flags
            return  t 'no unseen message'
        if @isFlags 'FLAGGED', filter.flags
            return  t 'no flagged message'
        if @isFlags 'ATTACH', filter.flags
            return t 'no filter message'
        return  t 'list empty'

    # Uniq Key from URL params
    #
    # return a {string}
    getKey: (str = '') ->
        if (filter = RouterStore.getQueryParams())
            keys = _.compact ['before', 'after'].map (key) ->
                filter[key] if filter[key] isnt '-'
            keys.unshift str unless _.isEmpty str
            return keys.join('-')
        return str

module.exports = new RouteGetter()
