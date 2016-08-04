{ActionTypes} = require '../constants/app_constants'

{AccountActions, MessageActions} = require '../constants/app_constants'

MessageGetter = require '../puregetters/messages'
RouterGetter = require '../puregetters/router'

{Route, Filter} = require '../models/route'

makeURIKey = require '../libs/urikey'

DEFAULT_TAB = 'account'

DEFAULT_STATE = new Route()

# This reducer expects the whole state as a 3rd param.
module.exports = (state = DEFAULT_STATE, action, appstate) ->

    switch action.type

        when ActionTypes.ROUTE_CHANGE
            throw new Error("malformed action") unless action.value
            {accountID, mailboxID, tab, filter, action: routeAction,
            messageID, conversationID} = action.value

            if appstate.get('accounts').size
                if mailboxID
                    if messageID and conversationID
                        routeAction = MessageActions.SHOW
                    else if accountID and routeAction isnt AccountActions.EDIT
                        routeAction = MessageActions.SHOW_ALL

            routeAction ?= AccountActions.CREATE

            # get Account from mailbox
            if mailboxID and not accountID
                accountID = RouterGetter.getAccountByMailbox appstate, mailboxID
                                        ?.get('id')

            # or default mailbox for account
            else if accountID and not mailboxID
                mailboxID = RouterGetter.getAllAccounts(appstate)
                                        .get(accountID)
                                        ?.get 'inboxMailbox'

            # Get default account
            # and set accountID and mailboxID
            if not accountID or not mailboxID
                account = RouterGetter.getDefaultAccount(appstate)
                accountID = account?.get 'id'
                mailboxID = account?.get 'inboxMailbox'

            # Make sure we always have both
            if not messageID or not conversationID
                conversationID = null
                messageID = null

            currentFilter = new Filter(filter)

            if routeAction isnt AccountActions.EDIT then tab = null
            else tab ?= DEFAULT_TAB

            state = state.merge
                tab: tab
                action: routeAction
                mailboxID: mailboxID
                accountID: accountID
                conversationID: conversationID
                messageID: messageID
                messagesFilter: currentFilter

            return state.set('URIKey', makeURIKey(state))

        when ActionTypes.CONVERSATION_FETCH_SUCCESS
            {result, conversationID} = action.value

            currentMessageInConversation = result?.messages?.find (msg) ->
                msg.id is state.get('messageID')

            # If messageID doesnt belong to conversation
            # message must have been deleted
            # then get default message from this conversation
            if state.get('conversationID') is conversationID and
            not currentMessageInConversation

                # At first get unread Message
                # if not get last message
                mailboxID = state.get('mailboxID')

                conv = MessageGetter.getConversation(conversationID, mailboxID)

                replacement = conv.find((message) -> message.isUnread()) or
                          conv.shift()

                if replacement then return state.set
                    messageID: replacement.get('id')
                    conversationID: conversationID

            # else
            return state


        when ActionTypes.REMOVE_ACCOUNT_SUCCESS
            account = RouterGetter.getDefaultAccount(appstate)

            state = state.merge
                accountID: account?.get 'id'
                mailboxID: account?.get 'inboxMailbox'
                tab: DEFAULT_TAB

            return state

        when ActionTypes.GO_TO_NEXT
            messages = RouterGetter.getMessagesList(appstate)
            ids = messages.keySeq().toArray()
            index = ids.indexOf state.route.messageID
            message = messages.get(ids[index - 1])
            state = state.merge
                messageID: message?.get

        when ActionTypes.GO_TO_PREVIOUS
            messages = RouterGetter.getMessagesList(appstate)
            ids = messages.keySeq().toArray()
            index = ids.indexOf state.route.messageID
            message = messages.get(ids[index + 1])

        # HANDLE NEAREST MESSAGE ON DELETETION
        # Get nearest message from message to be deleted
        # to make redirection if request is successful
        when ActionTypes.MESSAGE_TRASH_REQUEST
            {target} = action.value
            if target.messageID is state.get('messageID')
                nearestMessage = RouterGetter.getNearestMessage(appstate)
                return state.set 'nearestMessage', nearestMessage

        # Delete nearestMessage
        # because it's beacame useless
        when ActionTypes.MESSAGE_TRASH_FAILURE
            {target} = action.value
            if target.messageID is state.get('messageID')
                return state.remove 'nearestMessage'

        # Select nearest message from deleted message
        # and remove message from mailbox and conversation lists
        when ActionTypes.MESSAGE_TRASH_SUCCESS
            {target} = action.value
            if target.messageID is state.get('messageID')
                nearestMessage = state.get('nearestMessage')
                state = state.merge
                    messageID: nearestMessage?.get('id')
                    conversationID: nearestMessage?.get('conversationID')

                return state


        when ActionTypes.RECEIVE_MESSAGE_DELETE
            messageID = action.value
            if messageID is state.get('messageID')
                nearestMessage = RouterGetter.getNearestMessage(appstate)
                state = state.merge
                    messageID: nearestMessage?.get('id')
                    conversationID: nearestMessage?.get('conversationID')

                return state

    return state
