{div, span, ul, li, table, tbody, tr, td, img, a, i} = React.DOM

AttachmentPreview = require './attachement_preview'
PopupMessageDetails = require './popup_message_details'
ParticipantMixin = require '../mixins/participant_mixin'
ContactLabel = require './contact_label'
messageUtils = require '../utils/message_utils'

{MessageFlags, Tooltips} = require '../constants/app_constants'


module.exports = React.createClass
    displayName: 'MessageHeader'

    propTypes:
        message: React.PropTypes.object.isRequired
        isDraft: React.PropTypes.bool
        isDeleted: React.PropTypes.bool

    mixins: [
        ParticipantMixin
    ]


    getInitialState: ->
        showDetails: false
        showAttachements: false


    render: ->
        avatar = messageUtils.getAvatar @props.message

        div key: "message-header-#{@props.message.get 'id'}",
            if avatar
                div className: 'sender-avatar',
                    img className: 'media-object', src: avatar
            div className: 'infos',
                @renderAddress 'from'
                @renderAddress 'to'
                @renderAddress 'cc'
                div className: 'indicators',
                    if @props.message.get('attachments').length
                        @renderAttachementsIndicator()
                    if MessageFlags.FLAGGED in @props.message.get('flags')
                        i className: 'fa fa-star'
                    if @props.isDraft
                        i className: 'fa fa-edit'
                    if @props.isDeleted
                        i className: 'fa fa-trash'
                div className: 'date',
                    messageUtils.formatDate @props.message.get 'createdAt'
                PopupMessageDetails
                    message: @props.message


    renderAddress: (field) ->
        users = @props.message.get field
        return unless users.length

        div
            className: "addresses #{field}",
            key: "address-#{field}",
                if field isnt 'from'
                    span null,
                        t "mail #{field}"
                @formatUsers(users)...


    renderAttachementsIndicator: ->
        attachments = @props.message.get('attachments')?.toJS() or []

        div
            className: 'attachments'
            'aria-expanded': @state.showAttachements
            onClick: (event) -> event.stopPropagation()
            i
                className: 'btn fa fa-paperclip fa-flip-horizontal'
                onClick: @toggleAttachments
                'aria-describedby': Tooltips.OPEN_ATTACHMENTS
                'data-tooltip-direction': 'left'

            div className: 'popup', 'aria-hidden': not @state.showAttachements,
                ul className: null,
                    for file in attachments
                        AttachmentPreview
                            ref: 'attachmentPreview'
                            file: file
                            key: file.checksum
                            preview: false


    toggleAttachments: ->
        @setState showAttachements: not @state.showAttachements
