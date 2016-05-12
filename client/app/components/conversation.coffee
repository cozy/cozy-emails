_ = require 'underscore'
React     = require 'react'
ReactDOM  = require 'react-dom'

{section, header, ul, li, span, i, p, h3, a, button} = React.DOM

Message = React.createFactory require './message'

RouterGetter = require '../getters/router'
LayoutGetter = require '../getters/layout'

RouterActionCreator = require '../actions/router_action_creator'

module.exports = React.createClass
    displayName: 'Conversation'


    componentDidMount: ->
        @_initScroll()
        @_getFullConversation()


    componentDidUpdate: ->
        @_initScroll()
        @_getFullConversation()


    _getFullConversation: ->
        {conversationID} = @props
        length = RouterGetter.getConversationLength {conversationID}
        if length and length isnt @props.conversation.length
            setTimeout ->
                RouterActionCreator.getConversation conversationID
            , 0


    renderMessage: (message) ->
        messageID = message.get 'id'
        Message _.extend RouterGetter.formatMessage(message),
            ref             : "message-#{messageID}"
            key             : "message-#{messageID}"
            messageID       : @props.messageID
            isActive        : @props.messageID is messageID
            message         : message


    render: ->
        unless @props.conversation?.length
            return section
                key: 'conversation'
                className: 'conversation panel'
                'aria-expanded': true,
                p null, t "app loading"

        section
            ref: "conversation-container"
            key: "conversation-#{@props.messageID}-container"
            className: 'conversation panel'
            'aria-expanded': true,

            header null,
                h3 className: 'conversation-title',
                    @props.subject

                button
                    className: 'clickable btn btn-default fa fa-close'
                    onClick: @closeConversation

            section
                key: "conversation-#{@props.messageID}-content"
                ref: 'scrollable',
                    @props.conversation.map @renderMessage


    closeConversation: ->
        RouterActionCreator.closeConversation()


    _initScroll: ->
        if not (scrollable = ReactDOM.findDOMNode @refs.scrollable) or scrollable.scrollTop
            return

        if (activeElement = scrollable.querySelector '[data-message-active="true"]')
            unless LayoutGetter.isVisible activeElement
                coords = activeElement.getBoundingClientRect()
                scrollable.scrollTop = coords.top
