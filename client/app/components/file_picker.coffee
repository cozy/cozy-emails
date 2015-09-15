{div, form, input, ul, li, span, i, a} = React.DOM

MessageUtils = require '../utils/message_utils'


# file picker file format = mailparser result
FileShape = React.PropTypes.shape
    fileName           : React.PropTypes.string
    length             : React.PropTypes.number
    contentType        : React.PropTypes.string
    generatedFileName  : React.PropTypes.string
    contentDisposition : React.PropTypes.string
    contentId          : React.PropTypes.string
    transferEncoding   : React.PropTypes.string
    # one or the other
    rawFileObject      : React.PropTypes.object
    url                : React.PropTypes.string


###
# File picker
#
# Available props
# - editable: boolean (false)
# - files: array
# - form: boolean (true) embed component inside a form element
# - valueLink: a ReactLink for files
# - messageID: string
###

FilePicker = React.createClass
    displayName: 'FilePicker'

    propTypes:
        editable: React.PropTypes.bool
        display:  React.PropTypes.func
        value:    React.PropTypes.instanceOf Immutable.Vector
        valueLink: React.PropTypes.shape
            value: React.PropTypes.instanceOf Immutable.Vector
            requestChange: React.PropTypes.func
        messageID: React.PropTypes.string


    getDefaultProps: ->
        editable: false
        valueLink:
            value: Immutable.Vector.empty()
            requestChange: ->

    getInitialState: ->
        files: @props.value or @props.valueLink.value
        target: false

    componentWillReceiveProps: (props) ->
        @setState files: props.value or props.valueLink.value

    addFiles: (files) ->
        files = (@_fromDOM file for file in files)
        files = @state.files.concat(files).toVector()

        @props.valueLink.requestChange files

    deleteFile: (file) ->
        files = @state.files.filter (f) ->
            f.get('generatedFileName') isnt file.generatedFileName
        .toVector()

        @props.valueLink.requestChange files

    displayFile: (file) ->
        if file.url
            window.open file.url
        else if file.rawFileObject
            window.open URL.createObjectURL file.rawFileObject
        else console.log "broken file : ", file

    render: ->
        classMain = 'file-picker'
        classMain += " #{@props.className}" if @props.className
        classZone = 'dropzone'
        classZone += " target" if @state.target
        div className: classMain,
            ul className: 'files list-unstyled',
                @state.files.toJS().map (file) =>
                    FileItem
                        key: file.generatedFileName
                        file: file
                        editable: @props.editable
                        delete: => @deleteFile file
                        display: => @displayFile file
                        messageID: @props.messageID

            if @props.editable
                div null,
                    # triggering "click" won't work if file input is hidden
                    span className: "file-wrapper",
                        input
                            type: "file",
                            multiple: "multiple",
                            ref: "file",
                            onChange: @handleFiles
                    div
                        className: classZone
                        ref: "dropzone",
                        onDragOver: @allowDrop,
                        onDragEnter: @onDragEnter,
                        onDragLeave: @onDragLeave,
                        onDrop: @handleFiles,
                        onClick: @onOpenFile,
                            i className: "fa fa-paperclip"
                            span null, t "picker drop here"

    onOpenFile: (e) ->
        e.preventDefault()
        jQuery(@refs.file.getDOMNode()).trigger "click"

    allowDrop: (e) ->
        e.preventDefault()

    onDragEnter: (e) ->
        if not @state.target
            @setState target: true

    onDragLeave: (e) ->
        if @state.target
            @setState target: false

    handleFiles: (e) ->
        e.preventDefault()
        files = e.target.files or e.dataTransfer.files
        @addFiles files
        @setState target: false

    # convert from DOM Files to file picker format
    _fromDOM: (file) ->
        idx = @state.files.filter (f) -> f.get('fileName') is file.name
            .count()
        name = file.name
        if idx > 0
            dotpos = file.name.indexOf '.'
            name = name.substring(0, dotpos) + '-' + (idx + 1) +
                name.substring(dotpos)

        return Immutable.Map
            fileName:           file.name
            length:             file.size
            contentType:        file.type
            rawFileObject:      file
            generatedFileName:  name
            contentDisposition: null
            contentId:          file.name
            transferEncoding:   null
            content:            null
            url:                null


            # reader = new FileReader()
            # reader.readAsDataURL(file)
            # reader.onloadend = (e) =>
            #     txt = e.target.result
            #     file.content = txt
            #     currentFiles.push file
            #     parsed++
            #     if parsed is files.length
            #         @props.valueLink.requestChange currentFiles
            #         @setState {files: currentFiles }




module.exports = FilePicker

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
FileItem = React.createClass
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
        return {}

    render: ->
        file = @props.file
        if not(file.url?) and not(file.rawFileObject)
            window.cozyMails.log(new Error "Wrong file #{JSON.stringify(file)}")
            file.url = "message/#{@props.messageID}/attachments/#{file.generatedFileName}"
        type = MessageUtils.getAttachmentType file.contentType
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

        li className: "file-item", key: @props.key,
            i className: "mime #{type} fa #{iconClass}"
            a
                className: 'file-name',
                target: '_blank',
                onClick: @doDisplay,
                href: file.url
                'data-file-url': file.url
                'data-file-name': file.generatedFileName
                'data-file-type': file.contentType
                file.generatedFileName

            span className: 'file-size',
                "\(#{(file.length / 1000).toFixed(1)}Ko\)"
            span className: 'file-actions',
                a
                    className: "fa fa-download"
                    href: "#{file.url}?download=1"
                if @props.editable
                    i className: "fa fa-times delete", onClick: @doDelete

    doDisplay: (e) ->
        e.preventDefault()
        e.stopPropagation()
        @props.display()

    doDelete: (e) ->
        e.preventDefault()
        e.stopPropagation()
        @props.delete()
