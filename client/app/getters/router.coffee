{MessageActions
AccountActions} = require '../constants/app_constants'

_         = require 'lodash'
Immutable = require 'immutable'
moment    = require 'moment'

AccountStore      = require '../stores/account_store'
MessageStore      = require '../stores/message_store'
NotificationStore = require '../stores/notification_store'
RequestsStore     = require '../stores/requests_store'
RouterStore       = require '../stores/router_store'
SearchStore       = require '../stores/search_store'

FileGetter    = require '../getters/file'
MessageGetter = require '../getters/message'


module.exports =

    hasNextPage: ->
        RouterStore.hasNextPage()


    isCurrentURL: (mailboxURL) ->
        isServer = false
        currentURL = RouterStore.getCurrentURL {isServer}

        current = currentURL.split('?')
        mailbox = mailboxURL.split('?')
        isSameMailbox = 0 is current[0].indexOf mailbox[0]
        isSameQuery = current[1] is mailbox[1]

        isSameMailbox and isSameQuery


    getURL: (params) ->
        RouterStore.getURL params


    getInboxID: (accountID) ->
        accountID ?= @getAccountID()
        AccountStore.getInbox(accountID)?.get 'id'


    getInboxMailboxes: (accountID) ->
        RouterStore.getAllMailboxes(accountID).filter (mailbox) ->
            AccountStore.isInbox accountID, mailbox.get('id'), true


    getOtherMailboxes: (accountID) ->
        RouterStore.getAllMailboxes(accountID).filter (mailbox) ->
            not AccountStore.isInbox accountID, mailbox.get('id'), true


    # Sometimes we need a real URL
    # insteadof changing route params with actionCreator
    # Usefull to allow user
    # to open accountInbox into a new window
    getInboxURL: (accountID) ->
        mailboxID = @getInboxID accountID
        action = MessageActions.SHOW_ALL
        resetFilter = true
        return @getURL {action, mailboxID, resetFilter}


    isTrashbox: (mailboxID) ->
        accountID = @getAccountID()
        mailboxID ?= @getMailboxID()
        AccountStore.isTrashbox accountID, mailboxID


    # Sometimes we need a real URL
    # insteadof changing route params with actionCreator
    # Usefull to allow user
    # to open accountConfiguration into a new window
    getConfigURL: (accountID) ->
        mailboxID = @getInboxID accountID
        action = AccountActions.EDIT
        resetFilter = true
        @getURL {action, mailboxID, resetFilter}


    getComposeURL: ->
        @getURL {action: MessageActions.CREATE}


    getCreateAccountURL: ->
        @getURL {action: AccountActions.CREATE}


    getAction: ->
        RouterStore.getAction()


    getReplyMessage: (messageID) ->
        isReply = @getAction() is MessageActions.EDIT
        MessageStore.getByID messageID unless isReply


    getFilter: ->
        RouterStore.getFilter()


    getSearch: ->
        SearchStore.getCurrentSearch()


    getSelectedTab: ->
        RouterStore.getSelectedTab()


    getModal: ->
        RouterStore.getModalParams()


    getMessagesList: (accountID, mailboxID) ->
        RouterStore.getMessagesList accountID, mailboxID


    getMessage: (messageID) ->
        messageID ?= RouterStore.getMessageID()
        MessageStore.getByID messageID


    getConversationLength: (conversationID) ->
        RouterStore.getConversationLength(conversationID) or 0


    getConversation: (conversationID, mailboxID) ->
        RouterStore.getConversation(conversationID, mailboxID) or []


    getConversationID: ->
        RouterStore.getConversationID()


    isPageComplete: ->
        RouterStore.isPageComplete()


    getSubject: ->
        @getMessage()?.get 'subject'


    getMessageID: ->
        RouterStore.getMessageID()


    getMailbox: (accountID, mailboxID) ->
        accountID ?= @getAccountID()
        mailboxID ?= @getMailboxID()
        AccountStore.getMailbox accountID, mailboxID


    getUnreadLength: (accountID) ->
        accountID ?= @getAccountID()
        AccountStore.getInbox(accountID)?.get 'nbUnread'


    getFlaggedLength: (accountID) ->
        accountID ?= @getAccountID()
        AccountStore.getInbox(accountID)?.get 'nbFlagged'


    getAccounts: ->
        AccountStore.getAll()


    getAccountSignature: ->
        RouterStore.getAccount()?.get 'signature'


    getAccountID: ->
        RouterStore.getAccountID()


    getAccount: (accountID) ->
        accountID ?= @getAccountID()
        RouterStore.getAccount()


    getMailboxID: ->
        RouterStore.getMailboxID()


    getLogin: ->
        @getMailbox()?.get 'login'


    # Here is local settings
    # global settings are not handled anymore
    # but should be in the future
    hasSettingsChanged: ->
        messageID = RouterStore.getMessageID()
        MessageStore.isImagesDisplayed messageID


    getLastSync: ->
        accountID = @getAccountID()

        # If current mailboxID is inbox
        # test Inbox instead of 1rst mailbox
        if (isInbox = AccountStore.isInbox accountID, @getMailboxID())
            # Gmail issue
            # Test \All tag insteadof \INBOX
            mailbox = AccountStore.getAllMailbox accountID
            mailbox ?= AccountStore.getInbox accountID

        mailbox ?= @getMailbox()
        mailbox?.get('lastSync')


    isMailboxLoading: ->
        RequestsStore.isRefreshing()


    isMailboxIndexing: ->
        accountID = @getAccountID()
        RequestsStore.isIndexing accountID


    isConversationLoading: ->
        RequestsStore.isConversationLoading()


    isRefreshError: ->
        RequestsStore.isRefreshError()



    formatMessage: (message) ->
        _getResources = ->
            message?.get('attachments').groupBy (file) ->
                contentType = file.get 'contentType'
                attachementType = FileGetter.getAttachmentType contentType
                if attachementType is 'image' then 'preview' else 'binary'

        _.extend MessageGetter.formatContent(message), {
            resources   : _getResources()
            isDraft     : RouterStore.isDraft message
            isDeleted   : RouterStore.isDeleted message
            isFlagged   : @isFlagged message
            isUnread    : @isUnread message
        }


    isFlagged: (message) ->
        RouterStore.isFlagged message


    isUnread: (message) ->
        RouterStore.isUnread message


    getEmptyMessage: ->
        if @isUnread()
            return  t 'no unseen message'
        if @isFlagged()
            return  t 'no flagged message'
        if RouterStore.isAttached()
            return t 'no filter message'
        return  t 'list empty'


    getToasts: ->
        NotificationStore.getToasts()
