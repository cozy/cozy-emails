_         = require 'underscore'
Immutable = require 'immutable'
XHRUtils = require '../utils/xhr_utils'

AppDispatcher = require '../app_dispatcher'

Store = require '../libs/flux/store/store'
AccountStore = require './account_store'
RouterStore = require '../stores/router_store'

RouterGetter = require '../getters/router'

{changeRealtimeScope} = require '../utils/realtime_utils'
{sortByDate} = require '../utils/misc'

{ActionTypes, MessageFlags, MessageActions} = require '../constants/app_constants'

EPOCH = (new Date(0)).toISOString()

class MessageStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    _messages = Immutable.OrderedMap()
    _currentMessages = Immutable.OrderedMap()
    _conversations = Immutable.Map()

    _fetching = 0

    _conversation = null
    _currentID = null

    _inFlightByRef = {}
    _inFlightByMessageID = {}
    _undoable = {}


    _setCurrentID = (messageID) ->
        _currentID = messageID

    _addInFlight = (request) ->
        _inFlightByRef[request.ref] = request
        request.messages.forEach (message) ->
            id = message.get('id')
            requests = (_inFlightByMessageID[id] ?= [])
            requests.push request

    _removeInFlight = (ref) ->
        request = _inFlightByRef[ref]
        delete _inFlightByRef[ref]
        request.messages.forEach (message) ->
            id = message.get('id')
            requests = _inFlightByMessageID[id]
            _inFlightByMessageID[id] = _.without requests, request
        return request

    _transformMessageWithRequest = (message, request) ->
        switch request.type
            when 'trash'
                {trashBoxID} = request
                if _isDraft(message)
                    message = null
                else
                    newMailboxIds = {}
                    newMailboxIds[trashBoxID] = -1
                    message = message.set 'mailboxIDs', newMailboxIds

            when 'move'
                mailboxIDs = message.get('mailboxIDs')
                {from, to} = request
                newMailboxIds = {}
                newMailboxIds[key] = value for key, value of mailboxIDs
                delete newMailboxIds[from]
                newMailboxIds[to] ?= -1
                message = message.set 'mailboxIDs', newMailboxIds

            when 'flag'
                flags = message.get('flags')
                {flag, op} = request
                if op is 'batchAddFlag' and flag not in flags
                    message = message.set 'flags', flags.concat [flag]

                else if op is 'batchRemoveFlag' and flag in flags
                    message = message.set 'flags', _.without flags, flag

        return message

    # Retrieve a batch of message with various criteria
    # target - is an {Object} wi h a property messageID or messageIDs or
    #          conversationID or messageIDs
    # target.accountID is needed to success Delete
    #
    # Returns an {Array} of {Immutable.Map} messages
    _getMixed = (target) ->
        if target.messageID
            return [_messages.get(target.messageID)]
        else if target.messageIDs
            return target.messageIDs.map (id) ->
                 _messages.get id
            .filter (message) -> message?
        else if target.conversationID
            return _messages.filter (message) ->
                message?.get('conversationID') is target?.conversationID
            .toArray()
        else throw new Error 'Wrong Usage : unrecognized target AS.getMixed'

    _isDraft = (message, draftMailbox) ->
        mailboxIDs = message.get 'mailboxIDs'
        mailboxIDs[draftMailbox] or MessageFlags.DRAFT in message.get('flags')

    _fetchMessage = (params={}) ->
        return if _self.isFetching()

        {messageID, action} = params
        mailboxID = AccountStore.getSelectedMailbox()?.get 'id'
        action ?= MessageActions.SHOW_ALL
        timestamp = Date.now()

        _fetching++

        callback = (err, rawMsg) ->
            _fetching--
            if err?
                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_FAILURE
                    value: {mailboxID}
            else
                nextURL = rawMsg?.links?.next

                # This prevent to override local updates
                # with older ones from server
                messages = if _.isArray(rawMsg) then rawMsg else rawMsg.messages
                messages?.forEach (message) -> message.updated = timestamp
                _saveMessage message for message in messages when message?

                unless messages.length
                    # either end of list or no messages, we stay open
                    changeRealtimeScope mailboxID, EPOCH

                else if (lastdate = _messages.last()?.get 'date')
                    changeRealtimeScope mailboxID, lastdate

                AppDispatcher.dispatch
                    type: ActionTypes.MESSAGE_FETCH_SUCCESS
                    value: {action, nextURL, messageID}

                # Message is not in the result
                # get next page
                if messageID and not _messages.toJS()[messageID]
                    AppDispatcher.dispatch
                        type: ActionTypes.MESSAGE_FETCH_REQUEST
                        value: {messageID, action: MessageActions.PAGE_NEXT}

        if action is MessageActions.PAGE_NEXT
            url = RouterStore.getNextURL()
            XHRUtils.fetchMessagesByFolder url, callback

        else if action is MessageActions.SHOW_ALL
            mailboxID = AccountStore.getSelectedMailbox()?.get 'id'
            url = RouterStore.getCurrentURL {action, mailboxID}
            XHRUtils.fetchMessagesByFolder url, callback

        else
            XHRUtils.fetchConversation messageID, callback

    _computeMailboxDiff = (oldmsg, newmsg) ->
        return {} unless oldmsg
        changed = false

        wasRead = MessageFlags.SEEN in oldmsg.get 'flags'
        isRead = MessageFlags.SEEN in newmsg.get 'flags'

        accountID = newmsg.get 'accountID'
        oldboxes = Object.keys oldmsg.get 'mailboxIDs'
        newboxes = Object.keys newmsg.get 'mailboxIDs'

        out = {}
        added = _.difference(newboxes, oldboxes)
        added.forEach (boxid) ->
            changed = true
            out[boxid] = nbTotal: +1, nbUnread: if isRead then 0 else +1

        removed = _.difference oldboxes, newboxes
        removed.forEach (boxid) ->
            changed = true
            out[boxid] = nbTotal: -1, nbUnread: if wasRead then -1 else 0

        stayed = _.intersection oldboxes, newboxes
        deltaUnread = if wasRead and not isRead then +1
        else if not wasRead and isRead then -1
        else 0

        if deltaUnread isnt 0
            changed = true

        out[accountID] = nbUnread: deltaUnread

        stayed.forEach (boxid) ->
            out[boxid] = nbTotal: 0, nbUnread: deltaUnread

        if changed
            return out
        else
            return false

    _saveMessage = (message) ->
        oldmsg = _messages.get message.id
        updated = oldmsg?.get 'updated'

        # only update message if new version is newer than
        # the one currently stored
        if not (message.updated? and updated? and updated > message.updated) and
           not message._deleted # deleted draft are empty, don't update them

            message.attachments   ?= []
            message.date          ?= new Date().toISOString()
            message.createdAt     ?= message.date
            message.flags         ?= []
            message.hasAttachments = message.attachments.length > 0
            message.attachments = message.attachments.map (file) ->
                Immutable.Map file
            message.attachments = Immutable.List message.attachments

            # message loaded from fixtures for test purpose have a docType
            # that may cause some troubles
            delete message.docType

            message.updated = Date.now()
            messageMap = Immutable.Map message
            messageMap.prettyPrint = ->
                return """
                    #{message.id} "#{message.from[0].name}" "#{message.subject}"
                """

            # FIXME : trier ici par conversation
            # et associer la propriété messageIDs
            # pour garder la trace des messages
            # TODO : garder _messages
            # mais faire aussi un _conversations
            _messages = _messages.set message.id, messageMap

            # Save Conversations
            conversationID = message.conversationID
            conversation = _conversations.get(conversationID)
            conversation ?= Immutable.List()
            if -1 is conversation.indexOf(message.id)
                conversation = conversation.push message.id
            _conversations = _conversations.set conversationID, conversation

            if message.accountID? and (diff = _computeMailboxDiff oldmsg, messageMap)
                AccountStore._applyMailboxDiff message.accountID, diff

    _deleteMessage = (message) ->
        _messages = _messages.remove (id = message.id)

        # Remove all references to this ID
        _messages = _messages.map (message) ->
            messageIDs = message.get 'messageIDs'
            if messageIDs? and -1 < (index = messageIDs.indexOf id)
                messageIDs = messageIDs.splice index, 1
                message = message.set 'messageIDs', messageIDs
            return message


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        # handle ActionTypes.MESSAGE_FETCH_REQUEST, (param)->
        #     _fetchMessage param
        #     @emit 'change'
        handle ActionTypes.ROUTE_CHANGE, (value) ->
            if value.action is MessageActions.SHOW_ALL
                _setCurrentID = AccountStore.getSelectedOrDefault()?.get 'id'
                messageID = @getCurrentID()
                _fetchMessage {action: MessageActions.SHOW_ALL, messageID}

            if value.query and RouterStore.isResetFilter()?
                _messages = _messages.clear()

            _setCurrentID messageID if messageID

            @emit 'change'

        handle ActionTypes.RECEIVE_RAW_MESSAGE, (message) ->
            _saveMessage message
            @emit 'change'

        handle ActionTypes.RECEIVE_RAW_MESSAGE_REALTIME, (message) ->
            _saveMessage message
            @emit 'change'

        handle ActionTypes.RECEIVE_RAW_MESSAGES, (messages) ->
            for message in messages when message?
                _saveMessage message
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, (accountID) ->
            _messages = _messages.filter (message) ->
                accountID isnt message.get 'accountID'
            .toOrderedMap()
            @emit 'change'

        handle ActionTypes.MESSAGE_TRASH_REQUEST, ({target, ref}) ->
            messages = _getMixed target
            target.accountID = messages[0].get 'accountID'
            trashBoxID = AccountStore.getSelected().get 'trashMailbox'
            _addInFlight {type: 'trash', trashBoxID, messages, ref}
            @emit 'change'

        handle ActionTypes.MESSAGE_TRASH_SUCCESS, ({target, updated, ref, next}) ->
            _undoable[ref] =_removeInFlight ref
            for message in updated
                if message._deleted
                    _deleteMessage message
                    _setCurrentID next?.get('id')
                else
                    _saveMessage message
            @emit 'change'

        handle ActionTypes.MESSAGE_FLAGS_SUCCESS, ({target, updated, ref}) ->
            _removeInFlight ref
            _saveMessage message for message in updated
            @emit 'change'

        handle ActionTypes.MESSAGE_FLAGS_FAILURE, ({target, ref}) ->
            _removeInFlight ref
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_REQUEST, ({target, from, to, ref}) ->
            messages = _getMixed target
            _addInFlight {type: 'move', from, to, messages, ref}
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_SUCCESS, ({target, updated, ref}) ->
            _undoable[ref] =_removeInFlight ref
            _saveMessage message for message in updated
            @emit 'change'

        handle ActionTypes.MESSAGE_MOVE_FAILURE, ({target, ref}) ->
            _removeInFlight ref
            @emit 'change'

        handle ActionTypes.MESSAGE_UNDO_TIMEOUT, ({ref}) ->
            delete _undoable[ref]

        handle ActionTypes.MESSAGE_FETCH_FAILURE, ->
            @emit 'change'

        # handle ActionTypes.CONVERSATION_FETCH_SUCCESS, ({updated}) ->
        #     for message in updated
        #         _saveMessage message
        #     @emit 'change'

        handle ActionTypes.MESSAGE_SEND_SUCCESS, ({message, action}) ->
            _saveMessage message
            # if conversationID and action in ['UNMOUNT', 'MESSAGE_SEND_REQUEST']
            #     @fetchConversation conversationID
            @emit 'change'

        # handle ActionTypes.QUERY_PARAMETER_CHANGED, ->
        #     AppDispatcher.waitFor [RouterStore.dispatchToken]
        #     if RouterStore.isResetFilter()?
        #         _messages = _messages.clear()
        #     @emit 'change'

        # # FIXME : charger également la conversation
        # handle ActionTypes.MESSAGE_CURRENT, (param) ->
        #     _setCurrentID param.messageID
        #     @emit 'change'

        # handle ActionTypes.SELECT_ACCOUNT, ->
        #     _setCurrentID null
        #     @emit 'change'

        handle ActionTypes.RECEIVE_MESSAGE_DELETE, (id) ->
            _deleteMessage {id}
            @emit 'change'

        handle ActionTypes.MAILBOX_EXPUNGE, (mailboxID) ->
            _messages = _messages.filter (message) ->
                not (mailboxID of message.get 'mailboxIDs')
            .toOrderedMap()
            @emit 'change'

        handle ActionTypes.SEARCH_SUCCESS, ({result}) ->
            for message in result.rows when message?
                _saveMessage message
            @emit 'change'


    ###
        Public API
    ###
    getCurrentID: ->
        return _currentID

    getByID: (messageID) ->
        if (message = _messages.get messageID)
            return _addMessageIDs message

    _addMessageIDs = (message) ->
        conversationID = message.get 'conversationID'
        message.set 'messageIDs', _conversations.get conversationID

    _getCurrentConversations = (mailboxID) ->
        __conv = {}
        _messages.filter (message) ->
            conversationID = message.get 'conversationID'
            __conv[conversationID] = true unless (exist = __conv[conversationID])
            inMailbox = mailboxID of message.get 'mailboxIDs'
            return inMailbox and not exist
        .map _addMessageIDs
        .toList()

    getMessagesToDisplay: (mailboxID) ->
        _currentMessages = _getCurrentConversations(mailboxID)?.toOrderedMap()
        return _currentMessages

    getConversationLength: (messageID) ->
        messageID ?= MessageStore.getCurrentID()
        message = _currentMessages.find (message) ->
            message.get('id') is messageID
        message.get('messageIDs')?.size


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
            messageID ?= @getCurrentID()
            message = @getByID messageID
            conversationID = message?.get 'conversationID'

        # If no specific action is precised
        # return contextual conversations
        unless _.isFunction param.transform
            return @getByID messageID

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

    isFetching: ->
        return _fetching > 0

    # FIXME : move this into RouterStore/RouterGetter
    getUndoableRequest: (ref) ->
        _undoable[ref]

_self = new MessageStore()

module.exports = _self
