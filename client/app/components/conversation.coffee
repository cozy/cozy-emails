_ = require 'underscore'
React     = require 'react'
ReactDOM  = require 'react-dom'

{section, header, ul, li, span, i, p, h3, a, button} = React.DOM
DomUtils = require '../utils/dom_utils'

{MessageFlags, MessageActions} = require '../constants/app_constants'

Message             = React.createFactory require './message'
ToolbarConversation = React.createFactory require './toolbar_conversation'

SettingsStore = require '../stores/settings_store'
RouterGetter = require '../getters/router'

# FIXME : use Getters instead of Stores
AccountStore        = require '../stores/account_store'
MessageStore        = require '../stores/message_store'
LayoutStore         = require '../stores/layout_store'
SelectionStore       = require '../stores/selection_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'

module.exports = React.createClass
    displayName: 'Conversation'

    mixins: [
        StoreWatchMixin [SelectionStore, MessageStore]
    ]

    componentDidMount: ->
        @_initScroll()

    componentDidUpdate: ->
        @_initScroll()

    getStateFromStores: ->
        return {
            message: RouterGetter.getMessage()
            conversation: RouterGetter.getConversation()
        }

    renderMessage: (message, index) ->
        accounts = AccountStore.getAll()
        accountID = RouterGetter.getAccountID()
        messageID = message.get 'id'
        Message
            ref                 : 'message'
            key                 : 'message-' + messageID
            message             : message
            active              : @props.messageID is messageID
            url                 : RouterGetter.getURL {messageID}
            selectedMailboxID   : @props.mailboxID
            useIntents          : LayoutStore.intentAvailable()
            trashMailbox        : accounts[accountID]?.trashMailbox
            displayHTML         : SettingsStore.get 'messageDisplayHTML'
            displayImages       : SettingsStore.get 'messageDisplayImages'
            confirmDelete       : SettingsStore.get 'messageConfirmDelete'


    render: ->
        unless @state.conversation?.length
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
                    mailboxID           : @props.mailboxID
                a
                    className: 'clickable btn btn-default fa fa-close'
                    href: RouterGetter.getURL
                        action: MessageActions.SHOW_ALL

            section
                ref: 'scrollable',
                    @state.conversation.map @renderMessage

    _initScroll: ->
        if not (scrollable = ReactDOM.findDOMNode @refs.scrollable) or scrollable.scrollTop
            return

        if (activeElement = scrollable.querySelector '[data-message-active="true"]')
            unless DomUtils.isVisible activeElement
                coords = activeElement.getBoundingClientRect()
                scrollable.scrollTop = coords.top
