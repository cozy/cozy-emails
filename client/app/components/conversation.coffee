_ = require 'underscore'
React     = require 'react'
ReactDOM  = require 'react-dom'

{section, header, ul, li, span, i, p, h3, a, button} = React.DOM
DomUtils = require '../utils/dom_utils'

{MessageFlags, MessageActions} = require '../constants/app_constants'

Message             = React.createFactory require './message'
ToolbarConversation = React.createFactory require './toolbar_conversation'

# FIXME : use Getters instead of Stores
LayoutStore         = require '../stores/layout_store'
SettingsStore = require '../stores/settings_store'
RouterGetter = require '../getters/router'

SelectionStore       = require '../stores/selection_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'

module.exports = React.createClass
    displayName: 'Conversation'

    mixins: [
        StoreWatchMixin [SelectionStore]
    ]

    componentDidMount: ->
        @_initScroll()

    componentDidUpdate: ->
        @_initScroll()

    getStateFromStores: (props) ->
        return {
            message: RouterGetter.getMessage()
            conversation: RouterGetter.getConversation()
            trashMailbox: RouterGetter.getTrashMailbox()
        }

    renderMessage: (message) ->
        messageID = message.get 'id'
        Message
            key                 : 'message-detail-' + messageID
            message             : message
            active              : @props.messageID is messageID
            url                 : RouterGetter.getURL {messageID}
            selectedMailboxID   : @props.mailboxID
            useIntents          : LayoutStore.intentAvailable()
            trashMailbox        : @state.trashMailbox
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
