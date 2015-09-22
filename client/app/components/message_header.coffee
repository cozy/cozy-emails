{div, span, i, img, a} = React.DOM
{MessageFlags} = require '../constants/app_constants'

PopupMessageDetails     = require './popup_message_details'
PopupMessageAttachments = require './popup_message_attachments'
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
                    if @props.message.get('attachments').length
                        PopupMessageAttachments
                            message: @props.message
                    if @props.active
                        if MessageFlags.FLAGGED in @props.message.get('flags')
                            i className: 'fa fa-star'
                        if @props.isDraft
                            a
                                href: "#edit/#{@props.message.get 'id'}",
                                i className: 'fa fa-edit'
                                span null, t "edit draft"

                        if @props.isDeleted
                            i className: 'fa fa-trash'
                div className: 'metas date',
                    messageUtils.formatDate @props.message.get 'createdAt'
                PopupMessageDetails
                    message: @props.message


    renderAddress: (field) ->
        users = @props.message.get field
        return unless users.length

        div
            className: "addresses #{field}"
            key: "address-#{field}",

            div className: 'addresses-wrapper',
                if field isnt 'from'
                    span null,
                        t "mail #{field}"
                @formatUsers(users)...

