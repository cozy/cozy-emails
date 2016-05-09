_          = require 'underscore'
React      = require 'react'
classNames = require 'classnames'

{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM

{MessageFlags} = require '../constants/app_constants'

colorhash = require '../utils/colorhash'

RouterActionCreator = require '../actions/router_action_creator'
LayoutActionCreator = require '../actions/layout_action_creator'

{Icon}       = require('./basic_components').factories
Participants = React.createFactory require './participants'

RouterGetter = require '../getters/router'
ContactGetter = require '../getters/contact'
SearchGetter = require '../getters/search'

module.exports = React.createClass
    displayName: 'MessagesItem'

    render: ->
        date    = RouterGetter.getCreatedAt @props.message, @props.isCompact
        avatar  = ContactGetter.getAvatar @props.message
        flags   = @props.message.get 'flags'

        participants = @getParticipants @props.message
        subject = @highlightSearch text: @props.message.get 'subject'
        message = @highlightSearch message: @props.message

        from  = @props.message.get('from')[0]
        backgroundColor = colorhash "#{from?.name} <#{from?.address}>"
        name = if from?.name then from?.name[0] else from?.address[0]

        li
            className:  classNames
                message:    true
                unseen:     MessageFlags.SEEN not in flags
                active:     @props.isActive
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
                        type: 'star'
                        className: 'hidden' if MessageFlags.FLAGGED not in flags

                div className: 'avatar-wrapper select-target',
                    if avatar?
                        img className: 'avatar', src: avatar
                    else
                        i
                            className: 'avatar placeholder'
                            style: {backgroundColor},
                            name

                div className: 'metas-wrapper',
                    div className: 'metas',

                        div className: 'participants ellipsable',
                            participants

                        div className: 'subject ellipsable',
                            subject

                        div className: 'date',
                            date

                        div className: 'extras',
                            if @props.message.get 'hasAttachments'
                                i className: 'attachments fa fa-paperclip'
                            if @props.conversationLengths > 1
                                span className: 'conversation-length',
                                    @props.conversationLengths
                        div className: 'preview ellipsable',
                            message


    highlightSearch: (props, options = null) ->
        {message, text} = props

        if message and not (text = message.get 'text')
            text = toMarkdown html if (html = message.get 'html')?

        text = (text or '').substr 0, 1024
        props = SearchGetter.highlightSearch text
        p options, props...


    onSelect: (event) ->
        event.stopPropagation()
        id = @props.message.get 'id'
        value = not @props.isSelected
        LayoutActionCreator.updateSelection {id, value}


    onMessageClick: (event) ->
        RouterActionCreator.gotoMessage
            messageID: @props.message.get 'id'


    getParticipants: (message) ->
        from = message.get 'from'
        to   = message.get('to').concat(message.get('cc')).filter (address) =>
            return address.address isnt @props.login and
                address.address isnt from[0]?.address
        separator = if to.length > 0 then ', ' else ' '
        p null,
            Participants
                participants: from
                ref: 'from'
                tooltip: false
            span null, separator
            Participants
                participants: to
                ref: 'to'
                tooltip: false
