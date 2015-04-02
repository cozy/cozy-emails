{div, span, ul, li, img, a, i} = React.DOM
MessageUtils = require '../utils/message_utils'


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
            if resources.binary
                for file in resources.binary
                    AttachmentPreview
                        ref: 'attachmentPreview'
                        file: file
                        key: file.checksum
                        preview: false



# TODO: externalize Attachments to its own component
AttachmentPreview = React.createClass
    displayName: 'AttachmentPreview'

    icons:
        'archive'      : 'fa-file-archive-o'
        'audio'        : 'fa-file-audio-o'
        'code'         : 'fa-file-code-o'
        'image'        : 'fa-file-image-o'
        'pdf'          : 'fa-file-pdf-o'
        'word'         : 'fa-file-word-o'
        'presentation' : 'fa-file-powerpoint-o'
        'spreadsheet'  : 'fa-file-excel-o'
        'text'         : 'fa-file-text-o'
        'video'        : 'fa-file-video-o'
        'word'         : 'fa-file-word-o'


    render: ->
        li key: @props.key,
            @renderIcon()
            a
                target: '_blank'
                href: @props.file.url,
                    # TODO: generate a thumb instead of loading raw file
                    img width: 90, src: @props.file.url if @props.preview
                    @props.file.generatedFileName
            ' - '
            a href: "#{@props.file.url}?download=1",
                i className: 'fa fa-download'
                @displayFilesize(@props.file.length)


    renderIcon: ->
        type = MessageUtils.getAttachmentType @props.file.contentType
        i className: "fa #{@icons[type] or 'fa-file-o'}"


    displayFilesize: (length) ->
        if length < 1024
            "#{length} octets"
        else if length < 1024*1024
            "#{0 | length / 1024} Ko"
        else
            "#{0 | length / (1024*1024)} Mo"
