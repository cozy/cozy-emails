React = require 'react'

{li, img, a, i} = React.DOM

MessageUtils = require '../utils/message_utils'

{Tooltips} = require '../constants/app_constants'

module.exports = React.createClass
    displayName: 'AttachmentPreview'

    render: ->
        if @props.isLink
            li key: @props.key,
                a
                    className: 'file-details'
                    target: '_blank'
                    href: @props.file.url
                    'aria-describedby': Tooltips.OPEN_ATTACHMENT
                    'data-tooltip-direction': 'top',
                        # TODO: generate a thumb instead of loading raw file
                        img height: 48, src: @props.file.url if @props.isPreview
                        @renderIcon()
                        @props.file.generatedFileName
                        @props.fileSize
                a
                    className: 'file-actions'
                    href: "#{@props.file.url}?download=1"
                    'aria-describedby': Tooltips.DOWNLOAD_ATTACHMENT
                    'data-tooltip-direction': 'top',
                        i className: 'fa fa-download'
        else
            li key: @props.key,
                @renderIcon()
                a
                    href: "#{@props.file.url}?download=1"
                    'aria-describedby': Tooltips.DOWNLOAD_ATTACHMENT
                    'data-tooltip-direction': 'left',
                    """#{@props.file.generatedFileName}
                    (#{@props.fileSize})"""

    renderIcon: ->
        i className: "mime #{@props.type} fa #{@props.icon}"
