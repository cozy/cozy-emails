_ = require 'underscore'
React     = require 'react'
ReactDOM  = require 'react-dom'
Immutable = require 'immutable'

{section, header, p, h3, button} = React.DOM

Message = React.createFactory require './message'

FlagsConstants = require '../constants/app_constants'

MessageUtils = require '../libs/format_message'
isVisible = require '../libs/is_visible'

_scrollToActive = ->
    el = ReactDOM.findDOMNode @
    activeElement = el.querySelector '[data-message-active="true"]'
    if activeElement? and not isVisible activeElement
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

    propTypes:
        isConversationLoading: React.PropTypes.bool.isRequired
        messages: React.PropTypes.instanceOf(Immutable.Map)
        contacts: React.PropTypes.instanceOf(Immutable.Map)
        messageID: React.PropTypes.string.isRequired
        accountID: React.PropTypes.string.isRequired
        subject: React.PropTypes.string.isRequired
        trashboxID: React.PropTypes.string.isRequired
        isTrashbox: React.PropTypes.bool.isRequired
        doCloseConversation: React.PropTypes.func.isRequired
        doMarkMessage: React.PropTypes.func.isRequired

    componentDidMount: ->
        unless @props.isConversationLoading
            _freezeHeader.call @
            _scrollToActive.call @


    componentWillReceiveProps: (nextProps) ->
        # If this conversation was removed
        # redirect to messages list from mailbox
        if nextProps.isConversationLoading and not nextProps.messages.size
            setTimeout @props.doCloseConversation, 0


    componentDidUpdate: ->
        unless @props.isConversationLoading
            _freezeHeader.call @
            _scrollToActive.call @


    componentWillUnmount: ->
        setTimeout =>
            message = @props.messages.find (msg) =>
                msg.get('id') is @props.messageID

            if message?.isUnread()
                accountID = @props.accountID
                messageID = message.get('id')
                @doMarkMessage {messageID, accountID}, FlagsConstants.SEEN
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
                    onClick: @props.doCloseConversation

            section
                key: "conversation-#{@props.messageID}-content"
                ref: 'conversation-content',
                    @props.messages.map (message) =>
                        messageID = message.get 'id'
                        isDeleted = message.inMailbox @props.trashboxID
                        Message _.extend MessageUtils.formatContent(message),
                            ref             : "message-#{messageID}"
                            key             : "message-#{messageID}"
                            accountID       : @props.accountID
                            messageID       : @props.messageID
                            contacts        : @props.contacts
                            isActive        : @props.messageID is messageID
                            isDraft         : message.isDraft()
                            isDeleted       : isDeleted
                            isFlagged       : message.isFlagged()
                            isUnread        : message.isUnread()
                            isTrashbox      : @props.isTrashbox
                            message         : message
                            resources       : message.getResources()
                            displayModal    : @props.displayModal
                            doDisplayImages : @props.doDisplayImages
                            doDeleteMessage : @props.doDeleteMessage
                            doGotoMessage   : @props.doGotoMessage
                    .toArray()
