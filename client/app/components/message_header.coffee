React = require 'react'
{header, div, span, span, i, a} = React.DOM

ContactLabel = React.createFactory require '../components/contact_label'
Avatar = React.createFactory require './avatar'

module.exports = React.createClass
    displayName: 'MessageHeader'


    gotoMessage: ->
        conversationID = @props.message?.get 'conversationID'
        messageID = @props.message?.get 'id'
        @props.doGotoMessage {conversationID, messageID}


    render: ->
        header
            onClick: @gotoMessage
            key: "message-header-#{@props.message.get 'id'}",

            if @props.contacts.get(@props.message.get('from')[0])
                span className: 'sender-avatar',
                    Avatar
                        participant: @props.message.get('from')[0]
                        contacts: @props.contacts

            div
                className: 'infos',
                @renderAddress 'from'
                @renderAddress 'to' if @props.active
                @renderAddress 'cc' if @props.active
                span className: 'metas indicators',
                    if @props.message.get('attachments').size
                        i
                            className: 'fa fa-paperclip'

                    if @props.active
                        if @props.isFlagged
                            i className: 'fa fa-star'

                        if @props.isDraft
                            a
                                href: "#message/#{@props.message.get 'id'}",
                                i className: 'fa fa-edit'
                                span null, t "edit draft"

                        if @props.isDeleted
                            i className: 'fa fa-trash'

                span className: 'metas date',
                    @props.createdAt


    renderAddress: (field) ->
        participants = @props.message.get(field)
        if participants?.length
            span
                className: "addresses #{field}"
                key: "address-#{field}",

                span className: 'addresses-wrapper',
                    if field isnt 'from'
                        span className: 'field',
                            t "mail #{field}"

                    participants.map (participant, index) =>
                        ContactLabel
                            key: "contact-#{field}-#{index}"
                            contacts: @props.contacts
                            participant: participant
                            createContact: @props.createContact
                            displayModal: @props.displayModal
