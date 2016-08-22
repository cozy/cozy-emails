React      = require 'react'
Immutable      = require 'immutable'
classNames = require 'classnames'

{div, p, li, a, span, i} = React.DOM

{Icon}       = require('./basics/components').factories
Participants = React.createFactory require './participants'

Avatar = React.createFactory require './avatar'
Format = require '../libs/format'

Message = require '../models/message'

module.exports = React.createClass
    displayName: 'MessagesItem'

    propTypes:
        message: React.PropTypes.instanceOf(Message).isRequired
        isActive: React.PropTypes.bool.isRequired
        login: React.PropTypes.string.isRequired
        contacts: React.PropTypes.instanceOf(Immutable.Map).isRequired
        conversationLength: React.PropTypes.number.isRequired

    getSubject: ->
        subject = (@props.message.get('subject') or '').substr 0, 1024
        props = [subject]
        p null, props...

    getParticipants: ->
        from    = @props.message.get 'from'
        cc      = @props.message.get('cc')
        to      = @props.message.get('to').concat(cc).filter (address) =>
            return address.address isnt @props.login and
                address.address isnt from[0]?.address
        separator = if to.length > 0 then ', ' else ' '
        {from, to, separator}

    render: ->
        {from, to, separator} = @getParticipants()
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
                    Avatar
                        participant: @props.message.get('from')[0]
                        contacts: @props.contacts

                div className: 'metas-wrapper',
                    div className: 'metas',

                        div className: 'participants ellipsable',
                            p null,
                                Participants
                                    participants: from
                                    contacts: @props.contacts
                                    ref: 'from'
                                    tooltip: false
                                    addContact: @props.addContact
                                span null, separator
                                Participants
                                    participants: to
                                    contacts: @props.contacts
                                    ref: 'to'
                                    tooltip: false
                                    addContact: @props.addContact

                        div className: 'subject ellipsable',
                            @getSubject()

                        div className: 'date',
                            Format.getCreatedAt @props.message

                        div className: 'extras',
                            if @props.message.get('attachements')?.size
                                i className: 'attachments fa fa-paperclip'
                            if @props.conversationLength > 1
                                span className: 'conversation-length',
                                    @props.conversationLength

    onMessageClick: ->
        conversationID = @props.message.get 'conversationID'
        @props.gotoConversation {conversationID}
