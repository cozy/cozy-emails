{div, span, ul, li, a, i} = React.DOM
MessageUtils = require '../utils/message_utils'

AttachmentPreview = require './attachement_preview'


module.exports = React.createClass
    displayName: 'MessageFooter'

    propTypes:
        message: React.PropTypes.object.isRequired


    render: ->
        div className: 'attachments',
            @renderAttachments()


    renderAttachments: ->
        attachments = @props.message.get('attachments')?.toJS() or []
        return unless attachments.length

        resources =_.groupBy attachments, (file) ->
            if MessageUtils.getAttachmentType(file.contentType) is 'image'
                'preview'
            else
                'binary'
        ul className: null,
            if resources.preview
                for file in resources.preview
                    AttachmentPreview
                        ref: 'attachmentPreview'
                        file: file
                        key: file.checksum
                        preview: true
                        previewLink: true
            if resources.binary
                for file in resources.binary
                    AttachmentPreview
                        ref: 'attachmentPreview'
                        file: file
                        key: file.checksum
                        preview: false
                        previewLink: true
