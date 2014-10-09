{div, form, input, ul, li, span, i, a} = React.DOM

MessageUtils = require '../utils/message_utils'

###
# File picker
#
# Available props
# - editable: boolean (false)
# - files: array
# - form: boolean (true) embed component inside a form element
# - valueLink: a ReactLink for files
###

FilePicker = React.createClass
    displayName: 'FilePicker'

    propTypes:
        editable: React.PropTypes.bool
        form:     React.PropTypes.bool
        display:  React.PropTypes.func
        value:    React.PropTypes.array
        valueLink: React.PropTypes.shape
            value: React.PropTypes.array
            requestChange: React.PropTypes.func

    getDefaultProps: ->
        editable: false
        form: true
        value: []
        valueLink:
            value: []
            requestChange: ->

    getInitialState: ->
        files: @_convertFileList @props.value or @props.valueLink.value

    componentWillReceiveProps: (props) ->
        files = @_convertFileList @props.value or @props.valueLink.value
        @setState files: files

    render: ->
        files = @state.files.map (file) =>
            doDelete = =>
                updated = @state.files.filter (f) ->
                    return f.name isnt file.name
                @props.valueLink.requestChange updated
                @setState {files: updated }
            options =
                key: file.name
                file: file
                editable: @props.editable
                delete: doDelete

            if @props.display?
                options.display = =>
                    @props.display file

            FileItem options

        container = if @props.form then form else div

        container className: 'file-picker',
            ul className: 'files list-unstyled',
                files
            if @props.editable
                div null,
                    # triggering "click" won't work if file input is hidden
                    span className: "file-wrapper",
                        input
                            type: "file",
                            multiple: "multiple",
                            ref: "file",
                            onChange: @handleFiles
                    div className: "dropzone",
                        ref: "dropzone",
                        onDragOver: @allowDrop,
                        onDrop: @handleFiles,
                        onClick: @onOpenFile,
                            i className: "fa fa-paperclip"
                            span null, t "picker drop here"

    onOpenFile: (e) ->
        e.preventDefault()
        jQuery(@refs.file.getDOMNode()).trigger "click"

    allowDrop: (e) ->
        e.preventDefault()

    handleFiles: (e) ->
        e.preventDefault()
        files = e.target.files or e.dataTransfer.files
        currentFiles = @state.files
        parsed = 0

        # convert file content to data url to store it later in local storage
        handle = (file) =>
            reader = new FileReader()
            reader.readAsDataURL(file)
            reader.onloadend = (e) =>
                txt = e.target.result
                file.content = txt
                currentFiles.push file
                parsed++
                if parsed is files.length
                    @props.valueLink.requestChange currentFiles
                    @setState {files: currentFiles }

        handle file for file in @_convertFileList files


    #
    # "private" methods
    #
    _convertFileList: (files) ->
        convert = (file) =>
            if File.prototype.isPrototypeOf(file)
                @_fromDOM file
            return file

        Array.prototype.map.call files, convert

    _fromDOM: (file) ->
        return {
            name:               file.name
            size:               file.size
            type:               file.type
            originalName:       null
            contentDisposition: null
            contentId:          null
            transferEncoding:   null
            content:            null
            url:                null
        }


module.exports = FilePicker

###
# Display a file item
#
# Props:
#  - file
#  - editable: boolean (false) allow to delete file
#  - (display): function
#  - (delete): function
###
FileItem = React.createClass
    displayName: 'FileItem'

    propTypes:
        file: React.PropTypes.shape({
            name: React.PropTypes.string
            type: React.PropTypes.string
            size: React.PropTypes.number
        }).isRequired
        editable: React.PropTypes.bool
        display:  React.PropTypes.func
        delete:   React.PropTypes.func

    getDefaultProps: ->
        return {
            editable: false
        }

    getInitialState: ->
        return {}

    render: ->
        file = @props.file
        type = MessageUtils.getAttachmentType file.type
        icons =
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
        iconClass = icons[type] or 'fa-file-o'

        if @props.display?
            name = a
                className: 'file-name',
                target: '_blank',
                onClick: @doDisplay,
                file.name
        else
            name = span className: 'file-name', file.name

        li className: "file-item", key: file.name,
            i className: "mime fa #{iconClass}"
            if @props.editable
                i className: "fa fa-times delete", onClick: @doDelete
            name
            div className: 'file-detail',
                span
                    'data-file-url': file.url,
                    "#{(file.size / 1000).toFixed(2)}Ko"

    doDisplay: (e) ->
        e.preventDefault
        @props.display()

    doDelete: (e) ->
        e.preventDefault
        @props.delete()
