_     = require 'underscore'
React = require 'react'

{div, span, i, img, a} = React.DOM
{MessageFlags} = require '../constants/app_constants'


PopupMessageAttachments = React.createFactory require './popup_message_attachments'
ParticipantMixin        = require '../mixins/participant_mixin'
messageUtils            = require '../utils/message_utils'


module.exports = React.createClass
    displayName: 'MessageHeader'

    propTypes:
        message: React.PropTypes.object.isRequired
        isDraft: React.PropTypes.bool
        isDeleted: React.PropTypes.bool

    mixins: [
        ParticipantMixin
    ]


    shouldComponentUpdate: (nextProps, nextState) ->
        should = not (_.isEqual(nextProps, @props))
        return should

    render: ->
        avatar = messageUtils.getAvatar @props.message

        div key: "message-header-#{@props.message.get 'id'}",
            if avatar
                div className: 'sender-avatar',
                    img className: 'media-object', src: avatar
            div className: 'infos',
                @renderAddress 'from'
                @renderAddress 'to' if @props.active
                @renderAddress 'cc' if @props.active
                div className: 'metas indicators',
                    if @props.message.get('attachments').size
                        PopupMessageAttachments
                            message: @props.message
                    if @props.active
                        if MessageFlags.FLAGGED in @props.message.get('flags')
                            i className: 'fa fa-star'
                        if @props.isDraft
                            a
                                href: "#message/#{@props.message.get 'id'}",
                                i className: 'fa fa-edit'
                                span null, t "edit draft"

                        if @props.isDeleted
                            i className: 'fa fa-trash'
                div className: 'metas date',
                    messageUtils.formatDate @props.message.get 'createdAt'


    renderAddress: (field) ->
        users = @props.message.get field
        return unless users.length

        div
            className: "addresses #{field}"
            key: "address-#{field}",

            div className: 'addresses-wrapper',
                if field isnt 'from'
                    span className: 'field',
                        t "mail #{field}"
                @formatUsers(users)...
