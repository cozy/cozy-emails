_ = require 'underscore'
React     = require 'react'
{section, header, ul, li, span, i, p, h3, a, button} = React.DOM

{MessageFlags} = require '../constants/app_constants'

Message             = React.createFactory require './message'
ToolbarConversation = React.createFactory require './toolbar_conversation'

RouterGetter = require '../getters/router'

# FIXME : use Getters instead of Stores
AccountStore        = require '../stores/account_store'
MessageStore        = require '../stores/message_store'
LayoutStore         = require '../stores/layout_store'

_compactMin = 3

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

    getStateFromStores: ->
        return {
            message: RouterGetter.getMessage()
            messages: (messages = RouterGetter.getConversationMessages())
            compact: if @state then @state.compact else true
            isCompacted: if @state then @state.isCompacted else false
        }

    renderMessage: (message, index) ->
        isCompactMode = not @state.isCompacted and @state.compact
        doCompact = index > 0 and index <= _compactMin
        if isCompactMode and doCompact
            hiddenSize = @state.messages?.size - _compactMin
            @state.isCompacted = true
            return button
                ref: 'button-expand'
                key: 'button-expand-' + message.get 'id'
                className: 'more'
                onClick: =>
                    @setState compact: false
                i className: 'fa fa-refresh'
                t 'load more messages', hiddenSize

        accounts = AccountStore.getAll()
        accountID = AccountStore.getSelectedOrDefault().get 'id'
        messageID = message.get('id')
        mailboxID = AccountStore.getSelectedMailbox()?.get 'id'
        Message
            ref                 : 'message'
            key                 : 'message-' + messageID
            message             : message
            active              : RouterGetter.isCurrentMessage messageID
            url                 : RouterGetter.getURL {messageID, mailboxID}
            mailboxes           : AccountStore.getSelectedMailboxes()
            selectedMailboxID   : mailboxID
            useIntents          : LayoutStore.intentAvailable()
            trashMailbox        : accounts[accountID]?.trashMailbox

    render: ->
        unless @state.messages?.size
            return section
                key: 'conversation'
                className: 'conversation panel'
                'aria-expanded': true,
                p null, t "app loading"

        conversationID = @state.message.get 'conversationID'
        subject = @state.message.get 'subject'

        # Starts components rendering
        section
            ref: 'conversation'
            className: 'conversation panel'
            'aria-expanded': true,

            header null,
                h3 className: 'conversation-title',
                    subject

                ToolbarConversation
                    key                 : 'ToolbarConversation-' + conversationID
                    conversationID      : conversationID
                    mailboxID           : (mailboxID = AccountStore.getSelectedMailbox()?.get 'id')
                a
                    className: 'clickable btn btn-default fa fa-close'
                    href: RouterGetter.getURL
                        action: 'message.list'
                        mailboxID: mailboxID

            @state.messages.map @renderMessage
