React = require 'react'

{div, ul, i} = React.DOM
{Tooltips} = require '../constants/app_constants'

AttachmentPreview = React.createFactory require './attachement_preview'

RouterGetter = require '../getters/router'
IconGetter = require '../getters/icon'


module.exports = React.createClass
    displayName: 'MessageAttachmentsPopup'

    mixins: [
        require 'react-onclickoutside'
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
            i
                className: 'btn fa fa-paperclip'
                onClick: @toggleAttachments
                'aria-describedby': Tooltips.OPEN_ATTACHMENTS
                'data-tooltip-direction': 'left'

            div
                className: 'popup'
                'aria-hidden': not @state.showAttachements,
    
                ul className: null,
                    for file in attachments
                        AttachmentPreview
                            ref: 'attachmentPreview'
                            key: "attachmentPreview-#{file.checksum}"
                            file: file
                            fileSize: RouterGetter.getFileSize file
                            icon: IconGetter.getAttachmentIcon file
