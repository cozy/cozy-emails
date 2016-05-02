_     = require 'underscore'
React = require 'react'
{header, div, span, span, i, img, a} = React.DOM

{Tooltips} = require '../constants/app_constants'

ContactLabel = React.createFactory require '../components/contact_label'

ContactGetter = require '../getters/contact'

RouterActionCreator = require '../actions/router_action_creator'

module.exports = React.createClass
    displayName: 'MessageHeader'

    gotoMessage: ->
        messageID = @props.message?.get('id')
        RouterActionCreator.gotoMessage {messageID}

    render: ->
        header
            onClick: @gotoMessage

            key: "message-header-#{@props.message.get 'id'}",
            if @props.avatar
                span
                    className: 'sender-avatar',
                    img
                        className: 'media-object'
                        src: @props.avatar

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
        if (contacts = @props.message.get field)?.length
            span
                className: "addresses #{field}"
                key: "address-#{field}",

                span className: 'addresses-wrapper',
                    if field isnt 'from'
                        span className: 'field',
                            t "mail #{field}"

                    _.map contacts, (contact, index) ->
                        ContactLabel
                            ref: "contact-#{field}"
                            key: "contact-#{field}-#{index}"
                            model: ContactGetter.getByAddress contact
                            address: ContactGetter.displayAddress contact
                            contact: contact
