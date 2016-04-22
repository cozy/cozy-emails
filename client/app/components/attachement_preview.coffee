React = require 'react'

{li, img, a, i} = React.DOM

MessageUtils = require '../utils/message_utils'

{Tooltips} = require '../constants/app_constants'

module.exports = React.createClass
    displayName: 'AttachmentPreview'

    render: ->
        li key: @props.key,
            a
                className: 'file-details'
                href: "#{@props.file.url}?download=1"
                'aria-describedby': Tooltips.OPEN_ATTACHMENT
                'data-tooltip-direction': 'top',
                    # TODO: generate a thumb instead of loading raw file
                    img height: 48, src: @props.file.url if @props.isPreview
                    @renderIcon()
                    @props.file.generatedFileName
                    @props.fileSize


    renderIcon: ->
        i className: "mime #{@props.type} fa #{@props.icon}"
