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

{ComposeActions} = require '../constants/app_constants'


module.exports = Panel = React.createClass
    displayName: 'Panel'

    mixins: [
        TooltipRefesherMixin
        RouterMixin
    ]

    # Build initial state from store values.
    getInitialState: ->
        @getStateFromStores()

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
                @props.action is 'compose.edit' or
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
        unless @state.accounts.get @props.accountID
            setTimeout =>
                @redirect
                    direction   : 'first'
                    action      : 'default'
            , 1
            return React.DOM.div null, 'redirecting'

        prefix = 'messageList-' + @props.mailboxID
        MessageList
            key         : MessageStore.getQueryKey prefix
            accountID   : @props.accountID
            mailboxID   : @props.mailboxID
            queryParams : MessageStore.getQueryParams()

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
            key                  : @props.action or 'compose'

        component = null

        # Generates an empty compose form
        if @props.action is 'compose'
            message = null
            component = Compose options

        # Generates the edit draft composition form.
        else if @props.action is 'edit' or
                @props.action is 'compose.edit'
            messageID = @props.messageID
            if (message = MessageStore.getByID messageID)
                options.key += '-' + messageID
                component = Compose _.extend options,
                    key: options.key + '-' + messageID
                    message: message

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
            selectedAccount       : AccountStore.getSelectedOrDefault()
            settings              : SettingsStore.get()
            isLoadingReply        : not MessageStore.getByID(@props.messageID)?
        }
