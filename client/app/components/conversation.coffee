_ = require 'underscore'
React     = require 'react'
ReactDOM  = require 'react-dom'

{section, header, ul, li, span, i, p, h3, a, button} = React.DOM
DomUtils = require '../utils/dom_utils'
MessageUtils = require '../utils/message_utils'

{MessageActions} = require '../constants/app_constants'

Message = React.createFactory require './message'

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
        }

    renderMessage: (message) ->
        messageID = message.get 'id'
        props = MessageUtils.formatContent message

        Message _.extend props, {
            ref         : 'message'
            key         : "message-#{messageID}"
            message     : message
            active      : @props.messageID is messageID
            resources   : RouterGetter.getResources message
        }

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
