_          = require 'underscore'
React      = require 'react'
classNames = require 'classnames'

{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM

{MessageFlags} = require '../constants/app_constants'

colorhash                    = require '../utils/colorhash'
MessageUtils                 = require '../utils/message_utils'

RouterActionCreator = require '../actions/router_action_creator'
LayoutActionCreator = require '../actions/layout_action_creator'

LayoutActionCreator = require '../actions/layout_action_creator'

{Icon}       = require('./basic_components').factories
Participants = React.createFactory require './participants'


module.exports = MessageItem = React.createClass
    displayName: 'MessagesItem'

    render: ->
        message = @props.message
        flags = message.get 'flags'

        classes = classNames
            message:    true
            unseen:     MessageFlags.SEEN not in flags
            active:     @props.isActive

        compact = @props.isCompact
        date    = MessageUtils.formatDate message.get('createdAt'), compact
        avatar  = MessageUtils.getAvatar message

        li
            className:              classes
            key:                    @props.key
            'data-message-active':  @props.isActive
            draggable:              false
            onClick:                @onMessageClick

            a
                ref:               'target'
                className:         'wrapper'

                div className: 'markers-wrapper',
                    Icon
                        type: 'new-icon'
                        className: 'hidden' if MessageFlags.SEEN in flags

                    Icon
                        className: 'select'
                        onClick:   @onSelect
                        type: if @props.isSelected then 'check-square-o' else 'square-o'

                    Icon
                        type: 'star'
                        className: 'hidden' if MessageFlags.FLAGGED not in flags


                div className: 'avatar-wrapper select-target',
                    if avatar?
                        img className: 'avatar', src: avatar
                    else
                        from  = message.get('from')[0]
                        cHash = "#{from?.name} <#{from?.address}>"
                        i
                            className: 'avatar placeholder'
                            style:
                                backgroundColor: colorhash(cHash)
                            if from?.name then from?.name[0] else from?.address[0]

                div className: 'metas-wrapper',
                    div className: 'metas',
                        div className: 'participants ellipsable',
                            @getParticipants message
                        div className: 'subject ellipsable',
                            @highlightSearch message.get('subject')
                        div className: 'mailboxes',
                            @props.tags.map (tag) ->
                                span className: 'mailbox-tag', tag

                        div className: 'date',
                            # TODO: use time-elements component here for the date
                            date
                        div className: 'extras',
                            if message.get 'hasAttachments'
                                i className: 'attachments fa fa-paperclip'
                            if @props.conversationLengths > 1
                                span className: 'conversation-length',
                                    "#{@props.conversationLengths}"
                        div className: 'preview ellipsable',
                            @highlightSearch MessageUtils.getPreview(message)

    highlightSearch: (text, opts = null) ->
        return p opts, MessageUtils.highlightSearch(text)...

    onSelect: (event) ->
        event.stopPropagation()
        id = @props.message.get 'id'
        value = not @props.isSelected
        LayoutActionCreator.updateSelection {id, value}

    onMessageClick: (event) ->
        RouterActionCreator.gotoMessage
            messageID: @props.message.get 'id'

    onDragStart: (event) ->
        event.stopPropagation()
        id = @props.message.get 'id'
        value = not @props.isSelected
        LayoutActionCreator.updateSelection {id, value}

    onMessageClick: (event) ->
        RouterActionCreator.gotoMessage
            messageID: @props.message.get 'id'
            mailboxID: @props.message.get 'mailboxID'

    getParticipants: (message) ->
        from = message.get 'from'
        to   = message.get('to').concat(message.get('cc')).filter (address) =>
            return address.address isnt @props.login and
                address.address isnt from[0]?.address
        separator = if to.length > 0 then ', ' else ' '
        p null,
            Participants
                participants: from
                onAdd: @addAddress
                ref: 'from'
                tooltip: false
            span null, separator
            Participants
                participants: to
                onAdd: @addAddress
                ref: 'to'
                tooltip: false

    addAddress: (address) ->
        ContactActionCreator.createContact address
