React = require 'react'

{li, span, i, a} = React.DOM

ApiUtils        = require '../utils/api_utils'
{getFileURL}    = require '../utils/file_utils'

FileGetter = require '../getters/file'

###
# Display a file item
#
# Props:
#  - file
#  - editable: boolean (false) allow to delete file
#  - (display): function
#  - (delete): function
#  - (messageID): string
###
module.exports = FileItem = React.createClass
    displayName: 'FileItem'

    propTypes:
        file: React.PropTypes.shape({
            fileName: React.PropTypes.string
            contentType: React.PropTypes.string
            length: React.PropTypes.number
        }).isRequired
        editable:  React.PropTypes.bool
        display:   React.PropTypes.func
        delete:    React.PropTypes.func
        messageID: React.PropTypes.string

    getDefaultProps: ->
        return {
            editable: false
        }

    getInitialState: ->
        return 'tmpFileURL': getFileURL @props.file

    render: ->
        file = @props.file
        unless @state.tmpFileURL
            ApiUtils.log(new Error "Wrong file #{JSON.stringify(file)}")
            file.url = "message/#{@props.messageID}/attachments/#{file.generatedFileName}"

        iconClass = FileGetter.getAttachmentIcon file

        li className: "file-item", key: @props.key,
            i className: "mime #{type} fa #{iconClass}"
            a
                'className'         : 'file-name'
                'onClick'           : @doDisplay
                'data-file-url'     : @state.tmpFileURL
                'data-file-name'    : file.generatedFileName
                'data-file-type'    : file.contentType
                file.generatedFileName

            span className: 'file-size',
                "\(#{(file.length / 1000).toFixed(1)}Ko\)"
            span className: 'file-actions',
                a
                    'className' : 'fa fa-download'
                    'download'  : file.generatedFileName
                    'href'      : getFileURL file
                if @props.editable
                    i className: "fa fa-times delete", onClick: @doDelete

    doDisplay: (event) ->
        event.preventDefault()
        event.stopPropagation()
        @props.display @props.file

    doDelete: (event) ->
        event.preventDefault()
        event.stopPropagation()
        @props.delete @props.file
