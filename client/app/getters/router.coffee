AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'
LayoutStore = require '../stores/layout_store'
SearchStore = require '../stores/search_store'
RefreshesStore = require '../stores/refreshes_store'
RouterStore = require '../stores/router_store'

MessageUtils = require '../utils/message_utils'

_ = require 'lodash'
Immutable = require 'immutable'

{MessageActions, MailboxFlags} = require '../constants/app_constants'



class RouteGetter

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
        if (isReply = @getAction() isnt 'message.edit')
            return MessageStore.getByID messageID


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


    getLayoutSettings: ->
        {
            disposition: LayoutStore.getDisposition()
            isCompact: LayoutStore.getListModeCompact()
            previewSize: LayoutStore.getPreviewSize()
        }

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
        RouterStore.getConversation(messageID)


    getCurrentMessageID: ->
        RouterStore.getMessageID()


    getCurrentMessage: ->
        MessageStore.getByID RouterStore.getMessageID()


    isCurrentConversation: (conversationID) ->
        conversationID is @getCurrentMessage()?.get 'conversationID'


    getMailbox: (mailboxID) ->
        RouterStore.getMailbox mailboxID


    getCurrentMailbox: ->
        RouterStore.getMailbox()


    getInbox: (accountID) ->
        accountID ?= @getAccountID()
        RouterStore.getInbox accountID


    getTrashMailbox: (accountID) ->
        accountID ?= @getAccountID()
        RouterStore.getTrashMailbox accountID


    getAccounts: ->
        AccountStore.getAll()


    getAccountSignature: ->
        RouterStore.getAccount()?.get 'signature'


    getAccountID: ->
        RouterStore.getAccountID()


    getMailboxID: ->
        RouterStore.getMailboxID()


    getLogin: ->
        @getCurrentMailbox()?.get 'login'


    getMailboxes: ->
        RouterStore.getAllMailboxes()


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


    getEmptyMessage: ->
        if RouterStore.isFlags 'UNSEEN'
            return  t 'no unseen message'
        if RouterStore.isFlags 'FLAGGED'
            return  t 'no flagged message'
        if RouterStore.isFlags 'ATTACH'
            return t 'no filter message'
        return  t 'list empty'


    getResources: (message) ->
        if (files = message?.get 'attachments')
            files.groupBy (file) ->
                contentType = file.get 'contentType'
                attachementType = MessageUtils.getAttachmentType contentType
                if attachementType is 'image' then 'preview' else 'binary'


    getCreatedAt: (message) ->
        MessageUtils.formatDate message?.get 'createdAt'


    getFileSize: (file) ->
        length = parseInt file?.length, 10
        if length < 1024
            "#{length} #{t 'length bytes'}"
        else if length < 1024*1024
            "#{0 | length / 1024} #{t 'length kbytes'}"
        else
            "#{0 | length / (1024*1024)} #{t 'length mbytes'}"


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
