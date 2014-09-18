{div, form, input, ul, li, span, i, a} = React.DOM

MessageUtils = require '../utils/message_utils'

###
# File picker
#
# Available props
# - editable: boolean (false)
# - files: array
# - form: boolean (true) embed component inside a form element
# - display: function(Object) : called when a file is selected
# - onUpdate: function(Array) : called when file list is updated
###

FilePicker = React.createClass
    displayName: 'FilePicker'

    propTypes:
        files:    React.PropTypes.array
        editable: React.PropTypes.bool
        form:     React.PropTypes.bool
        display:  React.PropTypes.func
        onUpdate: React.PropTypes.func

    getDefaultProps: ->
        return {
            editable: false
            form: true
            files: []
            onUpdate: ->
        }

    getInitialState: ->
        return {
            files: @_convertFileList @props.files
        }

    componentWillReceiveProps: (props) ->
        @setState {files: @_convertFileList props.files}

    render: ->
        files = @state.files.map (file) =>
            doDelete = =>
                updated = @state.files.filter (f) -> return f.name isnt file.name
                @props.onUpdate updated
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
                    # triggering "click" won't work if file input itself is hidden
                    span className: "file-wrapper",
                        input type: "file", multiple: "multiple", ref: "file", onChange: @handleFiles
                    div className: "dropzone", ref: "dropzone", onDragOver: @allowDrop, onDrop: @handleFiles, onClick: @onOpenFile,
                        i className: "fa fa-paperclip"
                        span null, t "picker drop here"

    onOpenFile: (e) ->
        e.preventDefault()
        jQuery(@refs.file.getDOMNode()).trigger "click"

    allowDrop: (e) ->
        e.preventDefault()

    handleFiles: (e) ->
        e.preventDefault()
        files = e.target.files || e.dataTransfer.files
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
                    @props.onUpdate currentFiles
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
        iconClass = switch type
            when '' then 'fa-file-word-o'
            when 'archive'      then 'fa-file-archive-o'
            when 'audio'        then 'fa-file-audio-o'
            when 'code'         then 'fa-file-code-o'
            when 'image'        then 'fa-file-image-o'
            when 'pdf'          then 'fa-file-pdf-o'
            when 'word'         then 'fa-file-word-o'
            when 'presentation' then 'fa-file-powerpoint-o'
            when 'spreadsheet'  then 'fa-file-excel-o'
            when 'text'         then 'fa-file-text-o'
            when 'video'        then 'fa-file-video-o'
            when 'word'         then 'fa-file-word-o'
            else 'fa-file-o'

        if @props.display?
            name = a className: 'file-name', target: '_blank', onClick: @doDisplay, file.name
        else
            name = span className: 'file-name', file.name

        li className: "file-item", key: file.name,
            i className: "mime fa #{iconClass}"
            if @props.editable
                i className: "fa fa-times delete", onClick: @doDelete
            name
            div className: 'file-detail',
                span null, "#{(file.size / 1000).toFixed(2)}Ko"

    doDisplay: (e) ->
        e.preventDefault
        @props.display()

    doDelete: (e) ->
        e.preventDefault
        @props.delete()
