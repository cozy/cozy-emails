React      = require 'react'
classNames = require 'classnames'

{div, p, li, a, span, i, img} = React.DOM

RouterActionCreator = require '../actions/router_action_creator'

{Icon}       = require('./basics/components').factories
Participants = React.createFactory require './participants'

Format = require '../libs/format'
ContactGetter = require '../getters/contact'

Message = require '../models/message'

module.exports = React.createClass
    displayName: 'MessagesItem'

    propTypes:
        message: React.PropTypes.instanceOf(Message).isRequired
        isActive: React.PropTypes.bool.isRequired
        login: React.PropTypes.string.isRequired



    getSubject: ->
        subject = (@props.message.get('subject') or '').substr 0, 1024
        props = [subject]
        p null, props...


    getAvatar: ->
        ContactGetter.getAvatar @props.message


    getParticipants: ->
        from    = @props.message.get 'from'
        cc      = @props.message.get('cc')
        to      = @props.message.get('to').concat(cc).filter (address) =>
            return address.address isnt @props.login and
                address.address isnt from[0]?.address
        separator = if to.length > 0 then ', ' else ' '
        {from, to, separator}


    getBackgroundColor: ->
        from  = @props.message.get('from')[0]
        tag = "#{from?.name} <#{from?.address}>"
        ContactGetter.getTagColor tag


    getName: ->
        from  = @props.message.get('from')[0]
        if from?.name then from?.name[0] else from?.address[0]

    render: ->
        {from, to, separator} = @getParticipants()
        backgroundColor = @getBackgroundColor()

        li
            className:  classNames
                message:    true
                unseen:     @props.message.isUnread()
                active:     @props.isActive
            'data-message-active':  @props.isActive
            draggable:              false
            onClick:                @onMessageClick

            a
                ref:               'target'
                className:         'wrapper'

                div className: 'markers-wrapper',
                    Icon
                        type: 'new-icon'
                        className: 'hidden' unless @props.message.isUnread()

                    Icon
                        type: 'star'
                        className: 'hidden' unless @props.message.isFlagged()

                div className: 'avatar-wrapper select-target',
                    if (avatar = @getAvatar())?
                        img className: 'avatar', src: avatar
                    else
                        i
                            className: 'avatar placeholder'
                            style: {backgroundColor},
                            @getName()

                div className: 'metas-wrapper',
                    div className: 'metas',

                        div className: 'participants ellipsable',
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

                        div className: 'subject ellipsable',
                            @getSubject()

                        div className: 'date',
                            Format.getCreatedAt @props.message

                        div className: 'extras',
                            if @props.message.get('attachements')?.size
                                i className: 'attachments fa fa-paperclip'
                            if @props.conversationLengths > 1
                                span className: 'conversation-length',
                                    @props.conversationLengths


    onMessageClick: ->
        conversationID = @props.message.get 'conversationID'
        RouterActionCreator.gotoConversation {conversationID}
