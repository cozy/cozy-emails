_ = require 'underscore'
React     = require 'react'
ReactDOM  = require 'react-dom'

{section, header, ul, li, span, i, p, h3, a, button} = React.DOM
DomUtils = require '../utils/dom_utils'

{MessageFlags} = require '../constants/app_constants'

Message             = React.createFactory require './message'
ToolbarConversation = React.createFactory require './toolbar_conversation'

RouterGetter = require '../getters/router'

# FIXME : use Getters instead of Stores
AccountStore        = require '../stores/account_store'
MessageStore        = require '../stores/message_store'
LayoutStore         = require '../stores/layout_store'
SelectionStore       = require '../stores/selection_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'

module.exports = React.createClass
    displayName: 'Conversation'

    propTypes:
        messageID: React.PropTypes.string

    mixins: [
        StoreWatchMixin [SelectionStore, MessageStore]
    ]

    getInitialState: ->
        @getStateFromStores()

    componentWillReceiveProps: (nextProps={}) ->
        @setState @getStateFromStores()
        nextProps

    componentDidMount: ->
        @_initScroll()

    componentDidUpdate: ->
        @_initScroll()

    getStateFromStores: ->
        return {
            isLoading: RouterGetter.isLoading()
            message: RouterGetter.getMessage()
            messages: RouterGetter.getConversationMessages()
            # compactMin: 3
            # compact: if @state then @state.compact else true
            # isCompacted: if @state then @state.isCompacted else false
        }

    renderMessage: (message, index) ->
        # isCompactMode = not @state.isCompacted and @state.compact
        # doCompact = index <= @state.compactMin
        # if isCompactMode and doCompact
        #     hiddenSize = @state.messages?.size -  @state.compactMin
        #     @state.isCompacted = true
        #     return button
        #         ref: 'button-expand'
        #         key: 'button-expand-' + message.get 'id'
        #         className: 'more'
        #         onClick: =>
        #             @setState compact: false
        #         i className: 'fa fa-refresh'
        #         t 'load more messages', hiddenSize

        accounts = AccountStore.getAll()
        accountID = RouterGetter.getAccountID()
        messageID = message.get 'id'
        conversationID = message.get('conversationID')
        Message
            ref                 : 'message'
            key                 : 'message-' + messageID
            message             : message
            active              : RouterGetter.isCurrentConversation conversationID
            url                 : RouterGetter.getURL {messageID}
            selectedMailboxID   : @props.mailboxID
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
                    mailboxID           : @props.mailboxID
                a
                    className: 'clickable btn btn-default fa fa-close'
                    href: RouterGetter.getURL
                        action: 'message.list'

            section
                ref: 'scrollable',
                    @state.messages.map @renderMessage

    _initScroll: ->
        if not (scrollable = ReactDOM.findDOMNode @refs.scrollable) or scrollable.scrollTop
            return

        if (activeElement = scrollable.querySelector '[data-message-active="true"]')
            unless DomUtils.isVisible activeElement
                coords = activeElement.getBoundingClientRect()
                scrollable.scrollTop = coords.top
