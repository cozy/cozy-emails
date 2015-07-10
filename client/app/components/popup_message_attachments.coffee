{div, ul, i} = React.DOM
{Tooltips} = require '../constants/app_constants'

AttachmentPreview = require './attachement_preview'


module.exports = React.createClass
    displayName: 'MessageAttachmentsPopup'

    mixins: [
        OnClickOutside
    ]


    getInitialState: ->
        showAttachements: false


    toggleAttachments: ->
        @setState showAttachements: not @state.showAttachements


    handleClickOutside: ->
        @setState showAttachements: false


    render: ->
        attachments = @props.message.get('attachments')?.toJS() or []

        div
            className: 'attachments'
            'aria-expanded': @state.showAttachements
            onClick: (event) -> event.stopPropagation()
            i
                className: 'btn fa fa-paperclip'
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
