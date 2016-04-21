_     = require 'underscore'
React = require 'react'

{div, span, ul, li, a, i} = React.DOM

MessageUtils = require '../utils/message_utils'

AttachmentPreview = React.createFactory require './attachement_preview'


module.exports = React.createClass
    displayName: 'MessageFooter'

    propTypes:
        files: React.PropTypes.object.isRequired

    render: ->
        files = @props.files?.toJS() or []
        resources =_.groupBy files, (file) ->
            if MessageUtils.getAttachmentType(file.contentType) is 'image'
            then 'preview'
            else 'binary'

        div className: 'attachments',
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
