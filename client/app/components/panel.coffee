# Components
AccountConfig  = require './account_config'
Compose        = require './compose'
Conversation   = require './conversation'
MessageList    = require './message-list'
Settings       = require './settings'
SearchResult   = require './search_result'
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

MessageActionCreator = require '../actions/message_action_creator'

Constants = require '../constants/app_constants'
{ComposeActions, MessageFilter, Dispositions} = Constants


module.exports = Panel = React.createClass
    displayName: 'Panel'

    mixins: [
        StoreWatchMixin [AccountStore, MessageStore, SettingsStore, SearchStore]
        TooltipRefesherMixin
        RouterMixin
    ]


    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or
                 not (_.isEqual(nextProps, @props))

        return should

    render: ->
        # -- Generates a list of messages for a given account and mailbox
        if @props.action is 'account.mailbox.messages'
            @renderList()

        else if @props.action is 'search'

            key = encodeURIComponent SearchStore.getCurrentSearch()

            SearchResult
                key: "search-#{key}"

        # -- Generates a configuration window for a given account
        else if @props.action is 'account.config' or
                @props.action is 'account.new'

            id = @props.accountID or 'new'

            AccountConfig
                key: "account-config-#{id}"
                tab: @props.tab

        # -- Generates a conversation
        else if @props.action is 'message' or
                @props.action is 'conversation'

            Conversation
                messageID: @props.messageID
                key: 'conversation-' + @props.messageID
                ref: 'conversation'

        # -- Generates the new message composition form
        else if @props.action is 'compose' or
                @props.action is 'edit' or
                @props.action is 'compose.reply' or
                @props.action is 'compose.reply-all' or
                @props.action is 'compose.forward'

            @renderCompose()

        # -- Display the settings form
        else if @props.action is 'settings'

            Settings
                key     : 'settings'
                ref     : 'settings'
                settings: @state.settings

        # -- Error case, shouldn't happen. Might be worth to make it pretty.
        else
            console.error "Unknown action #{@props.action}"
            window.cozyMails.logInfo "Unknown action #{@props.action}"
            return React.DOM.div null, "Unknown component #{@props.action}"


    renderList: ->

        accountID = @props.accountID
        mailboxID = @props.mailboxID
        account   = AccountStore.getByID accountID

        if account?
            mailbox   = account.get('mailboxes').get mailboxID
            messages  = MessageStore.getMessagesToDisplay mailboxID,
                @state.settings.get('displayConversation')
            messagesCount = mailbox?.get('nbTotal') or 0
            emptyListMessage = switch @state.queryParams.filter
                when MessageFilter.FLAGGED
                    t 'no flagged message'
                when MessageFilter.UNSEEN
                    t 'no unseen message'
                when MessageFilter.ALL
                    t 'list empty'
                else
                    t 'no filter message'
        else
            setTimeout =>
                @redirect
                    direction: "first"
                    action: "default"
            , 1
            return React.DOM.div null, 'redirecting'

        # gets the selected message if any
        if @state.settings.get 'displayConversation'
            # select first conversation to allow navigation to start
            conversationID = @state.currentConversationID
            if not conversationID? and messages.length > 0
                conversationID = messages.first().get 'conversationID'
            conversationLengths = MessageStore.getConversationsLength()

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
            accounts:             @state.accounts
            mailboxes:            @state.mailboxes
            settings:             @state.settings
            fetching:             @state.fetching
            refresh:              @state.refresh
            isTrash:              isTrash
            conversationLengths:  conversationLengths
            emptyListMessage:     emptyListMessage
            ref:                  'messageList'
            displayConversations: displayConversations
            queryParams:          @state.queryParams
            canLoadMore:          @state.queryParams.hasNextPage
            loadMoreMessage: -> MessageActionCreator.fetchMoreOfCurrentQuery()

    # Rendering the compose component requires several parameters. The main one
    # are related to the selected account, the selected mailbox and the compose
    # state (classic, draft, reply, reply all or forward).
    renderCompose: ->
        options =
            layout               : 'full'
            action               : null
            inReplyTo            : null
            settings             : @state.settings
            accounts             : @state.accounts
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


    getStateFromStores: ->
        return {
            accounts              : AccountStore.getAll()
            mailboxes             : AccountStore.getAllMailboxes()
            selectedAccount       : AccountStore.getSelectedOrDefault()
            favoriteMailboxes     : AccountStore.getSelectedFavorites()
            selectedMailboxes     : AccountStore.getSelectedMailboxes(true)
            allMailboxes          : AccountStore.getAllMailboxes()
            accountWaiting        : AccountStore.isWaiting()
            fetching              : MessageStore.isFetching()
            queryParams           : MessageStore.getQueryParams()
            currentMessageID      : MessageStore.getCurrentID()
            conversation          : MessageStore.getCurrentConversation()
            currentConversationID : MessageStore.getCurrentConversationID()
            settings              : SettingsStore.get()
            isLoadingReply        : not MessageStore.getByID(@props.messageID)?
            refresh           : AccountStore.getMailboxRefresh @props.mailboxID
        }
