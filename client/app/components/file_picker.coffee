Immutable      = require 'immutable'
React          = require 'react'

{div, input, ul, span, i} = React.DOM

FileItem = React.createFactory require './file_item'

MessageUtils = require '../utils/message_utils'
{getFileURL} = require '../utils/file_utils'


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

module.exports = FilePicker = React.createClass
    displayName: 'FilePicker'

    propTypes:
        editable: React.PropTypes.bool
        display:  React.PropTypes.func
        value:    React.PropTypes.instanceOf Immutable.List
        valueLink: React.PropTypes.shape
            value: React.PropTypes.instanceOf Immutable.List
            requestChange: React.PropTypes.func
        messageID: React.PropTypes.string


    getDefaultProps: ->
        editable: false
        valueLink:
            value: Immutable.List()
            requestChange: ->

    getInitialState: ->
        files: @props.value or @props.valueLink.value
        target: false

    componentWillReceiveProps: (props) ->
        @setState files: props.value or props.valueLink.value

    addFiles: (files) ->
        files = (@_fromDOM file for file in files)
        files = @state.files.concat(files)

        @props.valueLink.requestChange files

    deleteFile: (file) ->
        files = @state.files.filter (f) ->
            f.get('generatedFileName') isnt file.generatedFileName

        @props.valueLink.requestChange files

    displayFile: (file) ->
        unless (url = getFileURL file)
            console.error "broken file : ", file
            return
        window.open url

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
                        delete: @deleteFile
                        display: @displayFile
                        messageID: @props.messageID

            if @props.editable
                div className: 'dropzone-wrapper',
                    # triggering "click" won't work if file input is hidden
                    span className: "file-wrapper",
                        input
                            type: "file",
                            multiple: "multiple",
                            ref: "file",
                            onChange: @handleFiles
                    div className: classZone,
                        i className: "fa fa-paperclip"
                        span null, t "picker drop here"
                    div
                        className: "dropzone dropzone-mask"
                        onDragOver: @allowDrop,
                        onDragEnter: @onDragEnter,
                        onDragLeave: @onDragLeave,
                        onDrop: @handleFiles,
                        onClick: @onOpenFile

    onOpenFile: (e) ->
        e.preventDefault()
        @refs.file.dispatchEvent new MouseEvent 'click'

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
        idx = @state.files
            .filter (f) -> f.get('fileName') is file.name
            .size
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
