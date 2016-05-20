{MailboxFlags
MessageActions
Requests
RequestStatus} = require '../constants/app_constants'

_         = require 'lodash'
Immutable = require 'immutable'
moment    = require 'moment'

AccountStore      = require '../stores/account_store'
MessageStore      = require '../stores/message_store'
NotificationStore = require '../stores/notification_store'
RefreshesStore    = require '../stores/refreshes_store'
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


    getAction: ->
        RouterStore.getAction()


    getReplyMessage: (messageID) ->
        isReply = @getAction() is MessageActions.EDIT
        MessageStore.getByID messageID unless isReply


    isEditable: ->
        action = @getAction()
        editables = [
            MessageActions.CREATE,
            MessageActions.EDIT,
            MessageActions.REPLY,
            MessageActions.REPLY_ALL,
            MessageActions.FORWARD
            ]
        action in editables


    getFilter: ->
        RouterStore.getFilter()


    getSearch: ->
        SearchStore.getCurrentSearch()


    getProgress: (accountID) ->
        RefreshesStore.getRefreshing().get accountID


    getSelectedTab: ->
        RouterStore.getSelectedTab()


    getModal: ->
        RouterStore.getModalParams()


    getMessagesList: (mailboxID) ->
        mailboxID ?= @getMailboxID()
        RouterStore.getMessagesList mailboxID


    getMessage: (messageID) ->
        messageID ?= RouterStore.getMessageID()
        MessageStore.getByID messageID


    getConversationLength: ({messageID, conversationID}) ->
        RouterStore.getConversationLength {messageID, conversationID}


    getConversation: (messageID) ->
        RouterStore.getConversation(messageID) or []


    getConversationID: ->
        RouterStore.getConversationID()


    getMessageID: ->
        RouterStore.getMessageID()


    isCurrentConversation: (conversationID) ->
        conversationID is @getConversationID()


    getMailbox: (mailboxID) ->
        RouterStore.getMailbox mailboxID


    getCurrentMailbox: ->
        RouterStore.getMailbox()


    getInbox: (accountID) ->
        accountID ?= @getAccountID()
        RouterStore.getInbox accountID


    getUnreadLength: ->
        @getInbox()?.get 'nbUnread'


    getFlaggedLength: ->
        @getInbox()?.get 'nbFlagged'


    getTrashMailbox: (accountID) ->
        accountID ?= @getAccountID()
        RouterStore.getTrashMailbox accountID


    getAccounts: ->
        AccountStore.getAll()


    getAccountSignature: ->
        RouterStore.getAccount()?.get 'signature'


    getAccountID: ->
        RouterStore.getAccountID()


    getAccount: (accountID) ->
        accountID ?= @getAccountID()
        RouterStore.getAccount()


    getAccountCreationBusy: ->
        RequestStatus.INFLIGHT in [
            RequestsStore.get(Requests.DISCOVER_ACCOUNT).status
            RequestsStore.get(Requests.CHECK_ACCOUNT).status
            RequestsStore.get(Requests.ADD_ACCOUNT).status
        ]


    getAccountIsDiscoverable: ->
        discover = RequestsStore.get Requests.DISCOVER_ACCOUNT
        check    = RequestsStore.get Requests.CHECK_ACCOUNT

        if discover.status is RequestStatus.SUCCESS
            return true
        # autodiscover failed w/o check in course: switch to manual config
        else if discover.status is RequestStatus.ERROR and check.status is null
            return false
        else
            return check.status is null


    getAccountCreationAlert: ->
        discover = RequestsStore.get Requests.DISCOVER_ACCOUNT
        check    = RequestsStore.get Requests.CHECK_ACCOUNT
        create   = RequestsStore.get Requests.ADD_ACCOUNT

        if create.status is RequestStatus.ERROR
            'CREATE_FAILED'

        else if check.status is RequestStatus.ERROR
            'CHECK_FAILED'

        # autodiscover failed: set an alert only if check isn't already
        # performed
        else if discover.status is RequestStatus.ERROR and check.status is null
            'DISCOVER_FAILED'

        else
            null


    getAccountIsOAuth: ->
        check = RequestsStore.get Requests.CHECK_ACCOUNT

        if check.status is RequestStatus.ERROR
            check.res.oauth
        else
            false


    getAccountCreationDiscover: ->
        discover = RequestsStore.get Requests.DISCOVER_ACCOUNT

        if discover.status is RequestStatus.SUCCESS
            discover.res
        else
            false


    getAccountCreationSuccess: ->
        create = RequestsStore.get Requests.ADD_ACCOUNT

        # return create request result (i.e. `{account}`) on success
        if create.status is RequestStatus.SUCCESS
            create.res
        else
            false


    getMailboxID: ->
        RouterStore.getMailboxID()


    getLogin: ->
        @getCurrentMailbox()?.get 'login'


    getMailboxes: ->
        RouterStore.getAllMailboxes()


    isMailboxLoading: ->
        RouterStore.isRefresh()


    getTags: (message) ->
        mailboxID = @getMailboxID()
        mailboxesIDs = Object.keys message.get 'mailboxIDs'
        return _.uniq _.compact mailboxesIDs.map (id) =>
            if (mailbox = @getMailbox id)
                attribs = mailbox.get('attribs') or []
                isGlobal = MailboxFlags.ALL in attribs
                isEqual = mailboxID is id
                unless (isEqual or isGlobal)
                    return mailbox?.get 'label'


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
