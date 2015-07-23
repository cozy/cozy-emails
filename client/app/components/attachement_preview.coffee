{li, img, a, i} = React.DOM
MessageUtils = require '../utils/message_utils'
{Tooltips} = require '../constants/app_constants'

module.exports = React.createClass
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
        if @props.previewLink
            li key: @props.key,
                @renderIcon()
                a
                    target: '_blank'
                    href: @props.file.url
                    'aria-describedby': Tooltips.OPEN_ATTACHMENT
                    'data-tooltip-direction': 'top',
                        # TODO: generate a thumb instead of loading raw file
                        img width: 90, src: @props.file.url if @props.preview
                        @props.file.generatedFileName
                ' - '
                a
                    href: "#{@props.file.url}?download=1"
                    'aria-describedby': Tooltips.DOWNLOAD_ATTACHMENT
                    'data-tooltip-direction': 'top',
                        i className: 'fa fa-download'
                        @displayFilesize(@props.file.length)
        else
            li key: @props.key,
                @renderIcon()
                a
                    href: "#{@props.file.url}?download=1"
                    'aria-describedby': Tooltips.DOWNLOAD_ATTACHMENT
                    'data-tooltip-direction': 'left',
                    """#{@props.file.generatedFileName}
                    (#{@displayFilesize(@props.file.length)})"""



    renderIcon: ->
        type = MessageUtils.getAttachmentType @props.file.contentType
        i className: "mime #{type} fa #{@icons[type] or 'fa-file-o'}"


    displayFilesize: (length) ->
        if length < 1024
            "#{length} #{t 'length bytes'}"
        else if length < 1024*1024
            "#{0 | length / 1024} #{t 'length kbytes'}"
        else
            "#{0 | length / (1024*1024)} #{t 'length mbytes'}"

