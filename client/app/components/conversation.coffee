_ = require 'underscore'
React     = require 'react'
{section, header, ul, li, span, i, p, h3, a, button} = React.DOM

{MessageFlags} = require '../constants/app_constants'

Message             = React.createFactory require './message'
ToolbarConversation = React.createFactory require './toolbar_conversation'

RouterGetter = require '../getters/router'

SettingsStore       = require '../stores/settings_store'
AccountStore        = require '../stores/account_store'
MessageStore        = require '../stores/message_store'
LayoutStore         = require '../stores/layout_store'

module.exports = React.createClass
    displayName: 'Conversation'

    propTypes:
        messageID: React.PropTypes.string

    # FIXME : use getters instead
    # such as : Conversation.getState()
    getInitialState: ->
        @getStateFromStores()

    # FIXME : use getters instead
    # such as : Conversation.getState()
    componentWillReceiveProps: (nextProps={}) ->
        @setState @getStateFromStores()
        nextProps

    # FIXME : use Getters here
    # FIXME : use smaller state
    getStateFromStores: ->
        message = MessageStore.getByID @props.messageID
        selectedAccount = AccountStore.getSelectedOrDefault()

        if message?
            conversationID = message?.get('conversationID')
            conversation = MessageStore.getConversation {conversationID}

        nextState =
            conversationID       : conversationID
            conversation         : conversation

        nextState.compact = true if @state?.compact isnt false

        if nextState.conversation?.size isnt @state?.conversation?.size
            nextState.expanded = []
            conversation?.forEach (message, key) ->
                isUnread = MessageFlags.SEEN not in message.get 'flags'
                isLast   = key is conversation.size - 1
                if (nextState.expanded.length is 0 and (isUnread or isLast))
                    nextState.expanded.push key
            nextState.compact = true

        return nextState

    renderMessage: (key, active) ->
        # allow the Message component to update current active message
        # in conversation. Needed to open the first unread message when
        # opening a conversation
        toggleActive = =>
            expanded = @state.expanded[..]
            if key in expanded
                expanded = expanded.filter (id) -> return key isnt id
            else
                expanded.push key
            @setState expanded: expanded

        accounts = AccountStore.getAll()
        accountID = AccountStore.getSelectedOrDefault().get 'id'

        Message
            ref                 : 'message'
            active              : active
            key                 : 'message-' + @props.messageID
            mailboxes           : AccountStore.getSelectedMailboxes()
            message             : @state.conversation.get key
            selectedMailboxID   : AccountStore.getSelectedMailbox()?.get 'id'
            settings            : SettingsStore.get()
            useIntents          : LayoutStore.intentAvailable()
            toggleActive        : toggleActive
            trashMailbox        : accounts[accountID]?.trashMailbox


    renderGroup: (messages, key) ->
        # if there are more than 3 messages, by default only render
        # first and last ones
        if messages.size > 3 and @state.compact
            items = []
            [first, ..., last] = messages
            items.push @renderMessage(first, false)
            items.push button
                className: 'more'
                onClick: =>
                    @setState compact: false
                i className: 'fa fa-refresh'
                t 'load more messages', messages.size - 2
            items.push @renderMessage(last, false)
        else
            items = (@renderMessage(key, false) for key in messages)

        return items


    render: ->
        if not @state.conversation or not (message = @state.conversation.get 0)
            return section
                key: 'conversation'
                className: 'conversation panel'
                'aria-expanded': true,
                p null, t "app loading"


        # Sort messages in conversation to find seen messages and group them
        messages = []
        lastMessageIndex = @state.conversation.size - 1
        @state.conversation.forEach (message, key) =>
            if key in @state.expanded
                messages.push key
            else
                [..., last] = messages
                messages.push(last = []) unless _.isArray(last)
                last.push key

        # Starts components rendering
        section
            ref: 'conversation'
            className: 'conversation panel'
            'aria-expanded': true,

            header null,
                h3 className: 'conversation-title',
                    message.get 'subject'

                ToolbarConversation
                    key                 : 'ToolbarConversation-' + @state.conversationID
                    conversationID      : @state.conversationID
                    mailboxID           : AccountStore.getSelectedMailbox()?.get 'id'
                    nextMessageID       : MessageStore.getNextConversation().get 'id'
                    previousMessageID   : MessageStore.getPreviousConversation().get 'id'
                    fullscreen          : LayoutStore.isPreviewFullscreen()
                a
                    className: 'clickable btn btn-default fa fa-close'
                    href: RouterGetter.getURL action: 'message.list'

            for glob, index in messages
                if _.isArray glob
                    @renderGroup glob, index
                else
                    @renderMessage glob, true
