AccountConfig  = require './account_config'
Compose        = require './compose'
Conversation   = require './conversation'
MessageList    = require './message-list'
Settings       = require './settings'

# React Mixins
StoreWatchMixin      = require '../mixins/store_watch_mixin'
TooltipRefesherMixin = require '../mixins/tooltip_refresher_mixin'

# Flux stores
AccountStore  = require '../stores/account_store'
MessageStore  = require '../stores/message_store'
SearchStore   = require '../stores/search_store'
SettingsStore = require '../stores/settings_store'

{MessageFilter, Dispositions} = require '../constants/app_constants'

module.exports = Application = React.createClass
    displayName: 'Panel'

    mixins: [
        StoreWatchMixin [AccountStore, MessageStore, SettingsStore]
        TooltipRefesherMixin
    ]


    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or
                 not (_.isEqual(nextProps, @props))
        return should

    render: ->
        # -- Generates a list of messages for a given account and mailbox
        if @props.action is 'account.mailbox.messages' or
           @props.action is 'account.mailbox.messages.full' or
           @props.action is 'search'

            @renderList()

        # -- Generates a configuration window for a given account
        else if @props.action is 'account.config' or
                @props.action is 'account.new'

            @renderAccount()

        # -- Generates a conversation
        else if @props.action is 'message' or
                @props.action is 'conversation'

            @renderConversation()

        # -- Generates the new message composition form
        else if @props.action is 'compose' or
                @props.action is 'edit'

            @renderCompose()

        # -- Display the settings form
        else if @props.action is 'settings'

            @renderSettings()

        # -- Error case, shouldn't happen. Might be worth to make it pretty.
        else
            console.error "Unknown action #{@props.action}"
            window.cozyMails.logInfo "Unknown action #{@props.action}"
            return React.DOM.div null, 'Unknown component'

    renderList: ->
        if @props.action is 'search'
            accountID = null
            mailboxID = null
            messages  = @state.results
            messagesCount    = messages.count()
            emptyListMessage = t 'list empty'
            counterMessage   = t 'list search count', messagesCount
        else
            accountID = @props.accountID
            mailboxID = @props.mailboxID
            account   = AccountStore.getByID accountID
            if account?
                mailbox   = account.get('mailboxes').get mailboxID
                messages  = MessageStore.getMessagesByMailbox mailboxID,
                    @state.settings.get('displayConversation')
                messagesCount = mailbox?.get('nbTotal') or 0
                emptyListMessage = switch @state.currentFilter
                    when MessageFilter.FLAGGED
                        t 'no flagged message'
                    when MessageFilter.UNSEEN
                        t 'no unseen message'
                    when MessageFilter.ALL
                        t 'list empty'
                    else
                        t 'no filter message'
                counterMessage   = t 'list count', messagesCount
            else
                @redirect
                    direction: "first"
                    action: "default"
                return

        # gets the selected message if any

        if @state.settings.get 'displayConversation'
            # select first conversation to allow navigation to start
            conversationID = @state.currentConversationID
            if not conversationID? and messages.length > 0
                conversationID = messages.first().get 'conversationID'
            conversationLengths = MessageStore.getConversationsLength()

        query = _.clone(@state.queryParams)
        query.accountID = accountID
        query.mailboxID = mailboxID

        # don't display conversations in Trash and Draft folders
        isDraft = @state.selectedAccount?.get('draftMailbox') is mailboxID
        isTrash = @state.selectedAccount?.get('trashMailbox') is mailboxID
        if isDraft or isTrash
            displayConversations = false
        else
            displayConversations = @state.settings.get 'displayConversation'

        return MessageList
            messages:             messages
            accountID:            accountID
            mailboxID:            mailboxID
            messageID:            @state.currentMessageID
            conversationID:       conversationID
            login:                account?.get 'login'
            mailboxes:            @state.mailboxesFlat
            settings:             @state.settings
            fetching:             @state.fetching
            query:                query
            isTrash:              isTrash
            conversationLengths:  conversationLengths
            emptyListMessage:     emptyListMessage
            ref:                  'messageList'
            displayConversations: displayConversations


    renderAccount: ->
        if @props.action is 'account.config'
            options =
                # don't use @state.selectedAccount
                ref               : "accountConfig"
                selectedAccount   : AccountStore.getSelected()
                error             : @state.accountError
                isWaiting         : @state.accountWaiting
                mailboxes         : @state.selectedMailboxes
                favoriteMailboxes : @state.favoriteMailboxes
                tab               : @props.tab
            if options.selectedAccount? and
               not options.error and
               options.mailboxes.length is 0
                options.error =
                    name: 'AccountConfigError'
                    field: 'nomailboxes'

        else if @props.action is 'account.new'
            options =
                ref       : "accountNew"
                error     : @state.accountError
                isWaiting : @state.accountWaiting

        return AccountConfig options

    renderConversation: ->
        messageID = @props.messageID
        mailboxID = @props.mailboxID
        message   = MessageStore.getByID messageID
        selectedMailboxID = @props.selectedMailboxID
        if message?
            conversationID     = message.get 'conversationID'
            lengths            = MessageStore.getConversationsLength()
            conversationLength = lengths.get conversationID
            conversation       = MessageStore.getConversation conversationID
            selectedMailboxID ?= Object.keys(message.get('mailboxIDs'))[0]

        # don't display conversations in Trash and Draft folders
        isDraft = @state.selectedAccount?.get('draftMailbox') is mailboxID
        isTrash = @state.selectedAccount?.get('trashMailbox') is mailboxID
        if isDraft or isTrash
            displayConversations = false
        else
            displayConversations = @state.settings.get 'displayConversation'

        prevMessage = MessageStore.getPreviousMessage()
        nextMessage = MessageStore.getNextMessage()

        return Conversation
            key: 'conversation-' + conversationID
            settings             : @state.settings
            accounts             : @state.accountsFlat
            mailboxes            : @state.mailboxesFlat
            selectedAccountID    : @state.selectedAccount.get 'id'
            selectedAccountLogin : @state.selectedAccount.get 'login'
            selectedMailboxID    : selectedMailboxID
            message              : message
            conversation         : conversation
            conversationLength   : conversationLength
            prevMessageID        : prevMessage?.get 'id'
            prevConversationID   : prevMessage?.get 'conversationID'
            nextMessageID        : nextMessage?.get 'id'
            nextConversationID   : nextMessage?.get 'conversationID'
            ref                  : 'conversation'
            displayConversations : displayConversations
            useIntents           : @props.useIntents


    renderCompose: ->
        options =
            layout               : 'full'
            action               : null
            inReplyTo            : null
            settings             : @state.settings
            accounts             : @state.accountsFlat
            selectedAccountID    : @state.selectedAccount.get 'id'
            selectedAccountLogin : @state.selectedAccount.get 'login'
            selectedMailboxID    : @props.selectedMailboxID
            useIntents           : @props.useIntents
            ref                  : 'compose'

        if @props.action is 'compose'
            options.message = null
        # -- Generates the edit draft composition form
        else if @props.action is 'edit'
            options.message = MessageStore.getByID @props.messageID

        return Compose options


    renderSettings: ->
        return Settings
            ref     : 'settings'
            settings: @state.settings


    getStateFromStores: ->

        selectedAccount = AccountStore.getSelected()
        # When selecting compose in Menu, we may not have a selected account
        if not selectedAccount?
            selectedAccount = AccountStore.getDefault()


        # Flat copies of accounts and mailboxes
        # This prevents components to refresh when properties they don't use are
        # updated (unread counts, timestamp of last refresh…)
        accountsFlat = {}
        AccountStore.getAll().map (account) ->
            accountsFlat[account.get 'id'] =
                name:  account.get 'name'
                label: account.get 'label'
                login: account.get 'login'
                trashMailbox: account.get 'trashMailbox'
                signature: account.get 'signature'
        .toJS()

        mailboxesFlat = {}
        AccountStore.getSelectedMailboxes().map (mailbox) ->
            id = mailbox.get 'id'
            mailboxesFlat[id] = {}
            ['id', 'label', 'depth'].map (prop) ->
                mailboxesFlat[id][prop] = mailbox.get prop
        .toJS()

        return {
            accountsFlat          : accountsFlat
            selectedAccount       : selectedAccount
            mailboxesFlat         : mailboxesFlat
            favoriteMailboxes     : AccountStore.getSelectedFavorites()
            selectedMailboxes     : AccountStore.getSelectedMailboxes()
            accountError          : AccountStore.getError()
            accountWaiting        : AccountStore.isWaiting()
            fetching              : MessageStore.isFetching()
            queryParams           : MessageStore.getParams()
            currentMessageID      : MessageStore.getCurrentID()
            currentConversationID : MessageStore.getCurrentConversationID()
            currentFilter         : MessageStore.getCurrentFilter()
            results               : SearchStore.getResults()
            settings              : SettingsStore.get()
        }
