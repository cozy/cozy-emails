# Components
AccountConfig  = require './account_config'
Compose        = require './compose'
Conversation   = require './conversation'
MessageList    = require './message-list'
Settings       = require './settings'
{Spinner}       = require './basic_components'

# React Mixins
RouterMixin          = require '../mixins/router_mixin'
StoreWatchMixin      = require '../mixins/store_watch_mixin'
TooltipRefesherMixin = require '../mixins/tooltip_refresher_mixin'

# Flux stores
AccountStore  = require '../stores/account_store'
MessageStore  = require '../stores/message_store'
SearchStore   = require '../stores/search_store'
SettingsStore = require '../stores/settings_store'

Constants = require '../constants/app_constants'
{ComposeActions, MessageFilter, Dispositions} = Constants


module.exports = Panel = React.createClass
    displayName: 'Panel'

    mixins: [
        StoreWatchMixin [AccountStore, MessageStore, SettingsStore]
        TooltipRefesherMixin
        RouterMixin
    ]


    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or
                 not (_.isEqual(nextProps, @props))

        return should

    render: ->
        # -- Generates a list of messages for a given account and mailbox
        if @props.action is 'account.mailbox.messages' or
           @props.action is 'account.mailbox.messages.filter' or
           @props.action is 'account.mailbox.messages.date' or
           @props.action is 'account.mailbox.default' or
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
                @props.action is 'edit' or
                @props.action is 'compose.reply' or
                @props.action is 'compose.reply-all' or
                @props.action is 'compose.forward'

            @renderCompose()

        # -- Display the settings form
        else if @props.action is 'settings'

            @renderSettings()

        # -- Error case, shouldn't happen. Might be worth to make it pretty.
        else
            console.error "Unknown action #{@props.action}"
            window.cozyMails.logInfo "Unknown action #{@props.action}"
            return React.DOM.div null, "Unknown component #{@props.action}"


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
                setTimeout =>
                    @redirect
                        direction: "first"
                        action: "default"
                , 1
                return div null, 'redirecting'

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
        conversationDisabledBoxes = [
            @state.selectedAccount?.get('trashMailbox')
            @state.selectedAccount?.get('draftMailbox')
            @state.selectedAccount?.get('junkMailbox')
        ]
        if mailboxID in conversationDisabledBoxes
            displayConversations = false
        else
            displayConversations = @state.settings.get 'displayConversation'

        isTrash = conversationDisabledBoxes[0] is mailboxID

        return MessageList
            key:                  'messageList-' + mailboxID
            messages:             messages
            accountID:            accountID
            mailboxID:            mailboxID
            messageID:            @state.currentMessageID
            conversationID:       conversationID
            login:                account?.get 'login'
            mailboxes:            @state.mailboxesFlat
            settings:             @state.settings
            fetching:             @state.fetching
            refresh:              @state.refresh
            query:                query
            isTrash:              isTrash
            conversationLengths:  conversationLengths
            emptyListMessage:     emptyListMessage
            ref:                  'messageList'
            displayConversations: displayConversations
            queryParams:          @state.queryParams
            filter:               @state.currentFilter


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
        conversationDisabledBoxes = [
            @state.selectedAccount?.get('trashMailbox')
            @state.selectedAccount?.get('draftMailbox')
            @state.selectedAccount?.get('junkMailbox')
        ]
        if mailboxID in conversationDisabledBoxes
            displayConversations = false
        else
            displayConversations = @state.settings.get 'displayConversation'

        prevMessage = MessageStore.getPreviousMessage()
        nextMessage = MessageStore.getNextMessage()

        # don't display conversation panel when there's no conversation
        # (happens sometime on deletion or filtering)
        return null unless conversationID?

        return Conversation
            key: 'conversation-' + conversationID
            settings             : @state.settings
            accounts             : @state.accountsFlat
            mailboxes            : @state.mailboxesFlat
            selectedAccountID    : @state.selectedAccount.get 'id'
            selectedAccountLogin : @state.selectedAccount.get 'login'
            selectedMailboxID    : selectedMailboxID
            conversationID       : conversationID
            conversation         : conversation
            conversationLength   : conversationLength
            prevMessageID        : prevMessage?.get 'id'
            prevConversationID   : prevMessage?.get 'conversationID'
            nextMessageID        : nextMessage?.get 'id'
            nextConversationID   : nextMessage?.get 'conversationID'
            ref                  : 'conversation'
            displayConversations : displayConversations
            useIntents           : @props.useIntents


    # Rendering the compose component requires several parameters. The main one
    # are related to the selected account, the selected mailbox and the compose
    # state (classic, draft, reply, reply all or forward).
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

        component = null

        # Generates an empty compose form
        if @props.action is 'compose'
            message = null
            component = Compose options

        # Generates the edit draft composition form.
        else if @props.action is 'edit'
            options.message = MessageStore.getByID @props.messageID
            component = Compose options

        # Generates the reply composition form.
        else if @props.action is 'compose.reply'
            options.action = ComposeActions.REPLY
            component = @getReplyComponent options

        # Generates the reply all composition form.
        else if @props.action is 'compose.reply-all'
            options.action = ComposeActions.REPLY_ALL
            component = @getReplyComponent options

        # Generates the forward composition form.
        else if @props.action is 'compose.forward'
            options.action = ComposeActions.FORWARD
            component = @getReplyComponent options
        else
            throw new Error "unknown compose type : #{@prop.action}"

        return component


    # Configure the component depending on the given action.
    # Returns a spinner if the message is not available.
    getReplyComponent: (options) ->
        message = MessageStore.getByID @props.messageID

        if not(@state.isLoadingReply) or message?
            message = MessageStore.getByID @props.messageID
            message.set 'id', @props.messageID
            options.inReplyTo = message
            component = Compose options
        else
            component = Spinner()

        return component


    renderSettings: ->
        return Settings
            ref     : 'settings'
            settings: @state.settings


    getStateFromStores: ->
        isLoadingReply = not MessageStore.getByID(@props.messageID)?

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
                name: account.get 'name'
                label: account.get 'label'
                login: account.get 'login'
                trashMailbox: account.get 'trashMailbox'
                signature: account.get 'signature'
        .toJS()

        mailboxesFlat = {}
        AccountStore.getSelectedMailboxes(true).map (mailbox) ->
            id = mailbox.get 'id'
            mailboxesFlat[id] = {}
            ['id', 'label', 'depth'].map (prop) ->
                mailboxesFlat[id][prop] = mailbox.get prop
        .toJS()

        refresh = AccountStore.getMailboxRefresh(@props.mailboxID)
        conversationID = MessageStore.getCurrentConversationID()
        conversation = if conversationID
            MessageStore.getConversation(conversationID)
        else null

        return {
            accountsFlat          : accountsFlat
            selectedAccount       : selectedAccount
            mailboxesFlat         : mailboxesFlat
            favoriteMailboxes     : AccountStore.getSelectedFavorites()
            selectedMailboxes     : AccountStore.getSelectedMailboxes(true)
            accountError          : AccountStore.getError()
            accountWaiting        : AccountStore.isWaiting()
            refresh               : refresh
            fetching              : MessageStore.isFetching()
            queryParams           : MessageStore.getParams()
            currentMessageID      : MessageStore.getCurrentID()
            conversation          : conversation
            currentConversationID : conversationID
            currentFilter         : MessageStore.getCurrentFilter()
            results               : SearchStore.getResults()
            settings              : SettingsStore.get()
            isLoadingReply        : isLoadingReply
        }
