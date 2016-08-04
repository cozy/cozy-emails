{MessageActions
AccountActions,
MessageFilter} = require '../constants/app_constants'

AccountGetter = require '../getters/account'
NotificationStore = require '../stores/notification_store'

MessageGetter = require '../getters/message'
reduxStore = require '../reducers/_store'

pure = require '../puregetters/router'
RequestsGetter = require '../puregetters/requests'

module.exports =

    getAction: ->
        pure.getAction reduxStore.getState()

    getFilter: ->
        pure.getFilter(reduxStore.getState()).toJS()

    getSelectedTab: ->
        pure.getSelectedTab reduxStore.getState()

    getModal: ->
        pure.getModal reduxStore.getState()

    getURL: (options) ->
        pure.getURL reduxStore.getState(), options

    getCurrentURL: ->
        pure.getCurrentURL reduxStore.getState()

    getDefaultAccount: ->
        pure.getDefaultAccount reduxStore.getState()

    getAccountID: ->
        pure.getAccountID(reduxStore.getState())

    getAccount: ->
        pure.getAccount(reduxStore.getState())

    getMailboxID: ->
        pure.getMailboxID(reduxStore.getState())

    getMailbox: (mailboxID)->
        pure.getMailbox(reduxStore.getState(), mailboxID)

    getAllMailboxes: (accountID) ->
        pure.getAllMailboxes(reduxStore.getState(), accountID)

    getConversationID: ->
        pure.getConversationID(reduxStore.getState())

    getMessageID: ->
        pure.getMessageID(reduxStore.getState())

    getFilterFunction: ->
        pure.getFilterFunction(reduxStore.getState())

    # MessageList have a minLength
    # if its size < minLength then return false
    # otherwhise return true
    isPageComplete: ->
        pure.isPageComplete(reduxStore.getState())

    getFetchURL: ->
        pure.getFetchURL reduxStore.getState()

    isLoading: ->
        pure.isLoading reduxStore.getState()

    getURI: ->
        pure.getURI(reduxStore.getState())

    getNextRequest: ->
        pure.getNextRequest(reduxStore.getState())

    getMessagesList: (accountID, mailboxID) ->
        pure.getMessagesList(reduxStore.getState(), accountID, mailboxID)

    getConversation: (conversationID, mailboxID) ->
        pure.getConversation(reduxStore.getState(), conversationID, mailboxID)

    getCurrentFlags: ->
        [].concat(@getFilter().flags)

    isUnread: ->
        MessageFilter.UNSEEN in @getCurrentFlags()  or
        @getMailboxID() is @getAccount()?.get('unreadMailbox')


    isFlagged: ->
        MessageFilter.FLAGGED in @getCurrentFlags() or
        @getMailboxID() is @getAccount()?.get('flaggedMailbox')


    isAttached: ->
        MessageFilter.ATTACH in @getCurrentFlags() or
        @getMailboxID() is @getAccount()?.get('unreadMailbox')


    getTrashBoxID: ->
        @getAccount()?.get('trashMailbox')

    isDeleted: ->
        # Mailbox selected is trashbox
        trashboxID = @getTrashBoxID()
        trashboxID? and trashboxID is @getMailboxID()

    isMessageDeleted: (message)->
        # Mailbox selected is trashbox
        trashboxID = @getAccounts().get(message.get('accountID'))
                                    .get('trashMailbox')
        trashboxID and message.inMailbox(trashboxID)

    isDraft: ->
        draftID = @getAccount()?.get 'draftMailbox'
        draftID? and draftID is @getMailboxID()

    hasNextPage: ->
        pure.hasNextPage reduxStore.getState()

    getMailboxTotal: ->
        prop = if @isUnread() then 'nbUnread'
        else if @isFlagged() then 'nbFlagged'
        else 'nbTotal'
        return @getMailbox()?.get(prop) or 0


    isActive: (mailboxID, flags) ->
        @getMailboxID() is mailboxID and @getFilter().flags is flags

    getInboxID: (accountID) ->
        accountID ?= @getAccountID()
        AccountGetter.getInbox(accountID)?.get 'id'

    getInboxMailboxes: (accountID) ->
        @getAllMailboxes(accountID).filter (mailbox) ->
            AccountGetter.isInbox accountID, mailbox.get('id'), true

    getOtherMailboxes: (accountID) ->
        @getAllMailboxes(accountID).filter (mailbox) ->
            not AccountGetter.isInbox accountID, mailbox.get('id'), true

    # Sometimes we need a real URL
    # insteadof changing route params with actionCreator
    # Usefull to allow user
    # to open accountInbox into a new window
    getInboxURL: (accountID) ->
        return @getURL
            action: MessageActions.SHOW_ALL
            mailboxID: @getInboxID accountID
            resetFilter: true


    isTrashbox: (mailboxID) ->
        accountID = @getAccountID()
        mailboxID ?= @getMailboxID()
        AccountGetter.isTrashbox accountID, mailboxID


    getConfigURL: (accountID) ->
        @getURL
            action: AccountActions.EDIT
            accountID: accountID

    getComposeURL: ->
        @getURL {action: MessageActions.CREATE}


    getCreateAccountURL: ->
        @getURL {action: AccountActions.CREATE}


    getReplyMessage: (messageID) ->
        isReply = @getAction() is MessageActions.EDIT
        MessageGetter.getByID messageID unless isReply

    getMessage: (messageID) ->
        messageID ?= @getMessageID()
        MessageGetter.getByID messageID

    getMessagesPerPage: ->
        pure.getMessagesPerPage reduxStore.getState()

    getConversationLength: (conversationID) ->
        conversationID ?= @getConversationID()
        MessageGetter.getConversationLength(conversationID) or 0


    getSubject: ->
        @getMessage()?.get 'subject'


    getUnreadLength: (accountID) ->
        accountID ?= @getAccountID()
        AccountGetter.getInbox(accountID)?.get 'nbUnread'


    getFlaggedLength: (accountID) ->
        accountID ?= @getAccountID()
        AccountGetter.getInbox(accountID)?.get 'nbFlagged'


    getAccounts: ->
        AccountGetter.getAll()


    getAccountSignature: ->
        @getAccount()?.get 'signature'


    getLogin: ->
        @getAccount()?.get 'login'


    # Here is local settings
    # global settings are not handled anymore
    # but should be in the future
    hasSettingsChanged: ->
        messageID = @getMessageID()
        MessageGetter.isImagesDisplayed messageID


    getLastSync: ->
        accountID = @getAccountID()
        mailboxID = @getMailboxID()

        # If current mailboxID is inbox
        # test Inbox instead of 1rst mailbox
        if (AccountGetter.isInbox accountID, mailboxID)
            # Gmail issue
            # Test \All tag insteadof \INBOX
            mailbox = AccountGetter.getAllMailbox accountID
            mailbox ?= AccountGetter.getInbox accountID

        mailbox ?= @getMailbox()
        mailbox?.get('lastSync')


    isMailboxLoading: ->
        RequestsGetter.isRefreshing reduxStore.getState()


    isMailboxIndexing: ->
        accountID = @getAccountID reduxStore.getState()
        RequestsGetter.isIndexing reduxStore.getState(), accountID


    isConversationLoading: ->
        RequestsGetter.isConversationLoading reduxStore.getState()


    isRefreshError: ->
        RequestsGetter.isRefreshError reduxStore.getState()

    getEmptyMessage: ->
        if @isUnread()                   then t 'no unseen message'
        else if @isFlagged()             then t 'no flagged message'
        else if @isAttached()            then t 'no filter message'
        else  t 'list empty'

    getToasts: ->
        NotificationStore.getToasts()
