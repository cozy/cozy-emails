_ = require 'underscore'
React     = require 'react'
ReactDOM  = require 'react-dom'

{section, header, ul, li, span, i, p, h3, a, button} = React.DOM

Message = React.createFactory require './message'

RouterGetter = require '../getters/router'
LayoutGetter = require '../getters/layout'

RouterActionCreator = require '../actions/router_action_creator'


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
        unless @props.isConversationLoading
            _freezeHeader.call @
            _scrollToActive.call @


    componentWillReceiveProps: (nextProps) ->
        # If this conversation was removed
        # redirect to messages list from mailbox
        if nextProps.isConversationLoading and not nextProps.messages.length
            setTimeout ->
                RouterActionCreator.closeConversation()
            , 0


    componentDidUpdate: ->
        unless @props.isConversationLoading
            _freezeHeader.call @
            _scrollToActive.call @


    componentWillUnmount: ->
        setTimeout =>
            RouterActionCreator.markAsRead @props
        , 0


    render: ->
        if @props.isConversationLoading
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
                    onClick: -> RouterActionCreator.closeConversation()

            section
                key: "conversation-#{@props.messageID}-content"
                ref: 'conversation-content',
                    @props.messages.map (message) =>
                        messageID = message.get 'id'
                        Message _.extend RouterGetter.formatMessage(message),
                            ref             : "message-#{messageID}"
                            key             : "message-#{messageID}"
                            messageID       : @props.messageID
                            isActive        : @props.messageID is messageID
                            isTrashbox      : RouterGetter.isTrashbox()
                            message         : message
