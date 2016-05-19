_ = require 'underscore'
React     = require 'react'
ReactDOM  = require 'react-dom'

{section, header, ul, li, span, i, p, h3, a, button} = React.DOM

Message = React.createFactory require './message'

RouterGetter = require '../getters/router'
LayoutGetter = require '../getters/layout'

RouterActionCreator = require '../actions/router_action_creator'


_getFullConversation = ->
    {conversationID, conversation} = @props
    length = RouterGetter.getConversationLength {conversationID}
    if length and length isnt conversation?.length
        setTimeout ->
            RouterActionCreator.getConversation conversationID
        , 0


_scrollToActive = ->
    el = ReactDOM.findDOMNode @
    activeElement = el.querySelector '[data-message-active="true"]'
    if activeElement? and not LayoutGetter.isVisible activeElement
        minHeight = @refs?['conversation-header'].scrollHeight
        el.scrollTop = activeElement.offsetTop - minHeight


_freezeHeader = ->
    headerEl = @refs?['conversation-header']
    contentEl = @refs?['conversation-content']
    isFixed = -1 < headerEl?.className.indexOf 'affix'
    if headerEl? and contentEl? and not isFixed
        contentEl.style.paddingTop = headerEl.scrollHeight
        headerEl.style.width = contentEl.offsetWidth
        headerEl.classList.add 'affix'


module.exports = React.createClass
    displayName: 'Conversation'


    componentDidMount: ->
        _getFullConversation.call @
        _freezeHeader.call @
        _scrollToActive.call @


    componentDidUpdate: ->
        _getFullConversation.call @


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
            className: 'conversation panel'
            'aria-expanded': true,

            header ref: "conversation-header",

                h3 className: 'conversation-title',
                    @props.subject

                button
                    className: 'clickable btn btn-default fa fa-close'
                    onClick: @closeConversation

            section
                key: "conversation-#{@props.messageID}-content"
                ref: 'conversation-content',
                    @props.conversation.map @renderMessage


    closeConversation: ->
        RouterActionCreator.closeConversation()
