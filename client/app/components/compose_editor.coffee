{div, button, textarea} = React.DOM

FileUtils    = require '../utils/file_utils'

module.exports = ComposeEditor = React.createClass
    displayName: 'ComposeEditor'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

    getInitialState: ->
        return {
            html: @props.html
            text: @props.text
            target: false     # true when hovering with a file
        }

    componentWillReceiveProps: (nextProps) ->
        if nextProps.messageID isnt @props.messageID
            @setState html: nextProps.html, text: nextProps.text

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))

    # Update parent component when content has been updated
    onHTMLChange: (event) ->
        @props.html.requestChange @refs.html.getDOMNode().innerHTML

    # Update parent component when content has been updated
    onTextChange: (event) ->
        @props.text.requestChange @refs.content.getDOMNode().value

    render: ->

        if @props.settings.get 'composeOnTop'
            classFolded = 'folded'
        else
            classFolded = ''
        classTarget = if @state.target then 'target' else ''

        div null,
            if @props.useIntents
                div className: "btn-group editor-actions",
                    button
                        className: "btn btn-default"
                        onClick: @choosePhoto,
                            span
                                className:'fa fa-image'
                                'aria-describedby': Tooltips.COMPOSE_IMAGE
                                'data-tooltip-direction': 'top'
            if @props.composeInHTML
                div
                    className: "form-control rt-editor #{classFolded} #{classTarget}",
                    ref: 'html',
                    contentEditable: true,
                    onKeyDown: @onKeyDown,
                    onInput: @onHTMLChange,
                    onDragOver: @allowDrop,
                    onDragEnter: @onDragEnter,
                    onDragLeave: @onDragLeave,
                    onDrop: @handleFiles,
                    # when dropping an image, input is fired before the image has
                    # really been added to the DOM, so we need to also listen to
                    # blur event
                    onBlur: @onHTMLChange,
                    dangerouslySetInnerHTML: {
                        __html: @state.html.value
                    }
            else
                textarea
                    className: "editor #{classTarget}",
                    ref: 'content',
                    onKeyDown: @onKeyDown,
                    onChange: @onTextChange,
                    onBlur: @onTextChange,
                    defaultValue: @state.text.value
                    onDragOver: @allowDrop,
                    onDragEnter: @onDragEnter,
                    onDragLeave: @onDragLeave,
                    onDrop: @handleFiles,

    _initCompose: ->

        if @props.composeInHTML
            @setCursorPosition()

            # Webkit/Blink and Gecko have some different behavior on
            # contentEditable, so we need to test the rendering engine
            # Webklink doesn't support insertBrOnReturn, so this will return
            # false
            gecko = document.queryCommandEnabled 'insertBrOnReturn'

            # Some DOM manipulation when replying inside the message.
            # When inserting a new line, we must close all blockquotes,
            # insert a blank line and then open again blockquotes
            jQuery('.rt-editor').on('keypress', (e) ->
                if e.keyCode isnt 13
                    # yes, our styleguide returning before the end of a
                    # function. But they also don't like lines longer than
                    # 80 characters
                    return

                # main function that remove quote at cursor
                quote = ->
                    # check whether a node is inside a blockquote
                    isInsideQuote = (node) ->
                        matchesSelector = document.documentElement.matches or
                              document.documentElement.matchesSelector or
                              document.documentElement.webkitMatchesSelector or
                              document.documentElement.mozMatchesSelector or
                              document.documentElement.oMatchesSelector or
                              document.documentElement.msMatchesSelector

                        if matchesSelector?
                            return matchesSelector.call node,
                                '.rt-editor blockquote, .rt-editor blockquote *'
                        else
                            while node? and node.tagName isnt 'BLOCKQUOTE'
                                node = node.parentNode
                            return node.tagName is 'BLOCKQUOTE'

                    # try to get the real target element
                    target = document.getSelection().anchorNode
                    if target.lastChild?
                        target = target.lastChild
                        if target.previousElementSibling?
                            target = target.previousElementSibling
                    targetElement = target
                    while targetElement and not (targetElement instanceof Element)
                        targetElement = targetElement.parentNode
                    if not target?
                        return
                    if not isInsideQuote(targetElement)
                        # we are not inside a blockquote, nothing to do
                        return

                    # Insert another break, then select it and use outdent to
                    # remove blocquotes
                    if gecko
                        br = "\r\n<br>\r\n<br class='cozyInsertedBr'>\r\n"
                    else
                        br = """
                          \r\n<div></div><div><br class='cozyInsertedBr'></div>\r\n
                            """
                    document.execCommand 'insertHTML', false, br

                    node = document.querySelector('.cozyInsertedBr')
                    if gecko
                        node = node.previousElementSibling

                    # get path of a node inside the contentEditable
                    getPath = (node) ->
                        path = node.tagName
                        while node.parentNode? and node.contentEditable isnt 'true'
                            node = node.parentNode
                            path = "#{node.tagName} > #{path}"
                        return path

                    # ensure focus is on newly inserted node
                    selection = window.getSelection()
                    range = document.createRange()
                    range.selectNode(node)
                    selection.removeAllRanges()
                    selection.addRange(range)

                    # outdent node
                    depth = getPath(node).split('>').length
                    while depth > 0
                        document.execCommand 'outdent', false, null
                        depth--
                    # remove the surnumerous block
                    node = document.querySelector '.cozyInsertedBr'
                    node?.parentNode.removeChild node

                    # try to remove format that may remains from the quote
                    document.execCommand 'removeFormat', false, null
                    return

                # timeout to let the editor perform its own stuff
                setTimeout quote, 50
            )

            # Allow to hide original message
            if document.querySelector('.rt-editor blockquote') and
               not document.querySelector('.rt-editor .originalToggle')
                try
                    header = jQuery('.rt-editor blockquote').eq(0).prev()
                    header.text(header.text().replace('…', ''))
                    header.append('<span class="originalToggle">…</>')
                    header.on 'click', ->
                        jQuery('.rt-editor').toggleClass('folded')
                catch e
                    console.error e

            else
                jQuery('.rt-editor .originalToggle').on 'click', ->
                    jQuery('.rt-editor').toggleClass('folded')

        else
            # Text message
            if @props.focus
                node = @refs.content.getDOMNode()

                if not @props.settings.get 'composeOnTop'
                    rect = node.getBoundingClientRect()
                    node.scrollTop = node.scrollHeight - rect.height

                    if (typeof node.selectionStart is "number")
                        node.selectionStart = node.value.length
                        node.selectionEnd   = node.value.length
                    else if (typeof node.createTextRange isnt "undefined")
                        setTimeout ->
                            node.focus()
                        , 0
                        range = node.createTextRange()
                        range.collapse(false)
                        range.select()

                setTimeout ->
                    node.focus()
                , 0


    # Put the selection cursor at the bottom of the message. The cursor is set
    # before the signature if there is one.
    setCursorPosition: ->
        if @props.focus
            node = @refs.html?.getDOMNode()
            if node?
                document.querySelector(".rt-editor").focus()
                if not @props.settings.get 'composeOnTop'

                    account = @props.accounts[@props.accountID]

                    signatureNode = document.getElementById "signature"
                    if account.signature? and
                    account.signature.length > 0 and
                    signatureNode?
                        node = signatureNode
                        node.innerHTML = """
                        <p><br /></p>
                        #{node.innerHTML}
                        """
                        node = node.firstChild

                    else
                        node.innerHTML += "<p><br /></p><p><br /></p>"
                        node = node.lastChild

                    if node?
                        # move cursor to the bottom
                        node.scrollIntoView(false)
                        node.innerHTML = "<br \>"
                        selection = window.getSelection()
                        range = document.createRange()
                        range.selectNodeContents node
                        selection.removeAllRanges()
                        selection.addRange range
                        document.execCommand 'delete', false, null
                        node.focus()


    componentDidMount: ->
        @_initCompose()

    componentDidUpdate: (oldProps, oldState) ->
        if oldProps.messageID isnt @props.messageID
            @_initCompose()

        # On account change, update message signature
        if oldProps.accountID isnt @props.accountID
            @_updateSignature()

    _updateSignature: ->
        signature = @props.accounts[@props.accountID].signature
        if @refs.html?
            signatureNode = document.getElementById "signature"
            if signature? and signature.length > 0
                signatureHtml = signature.replace /\n/g, '<br>'
                if signatureNode?
                    # replace old signature by new one
                    signatureNode.innerHTML = "-- \n<br>#{signatureHtml}</p>"
                else
                    # append new signature at the end of message
                    @refs.html.getDOMNode().innerHTML += """
                <p><br></p><p id="signature">-- \n<br>#{signatureHtml}</p>
                    """
            else
                # new account has no signature
                if signatureNode?
                    # delete old signature
                    signatureNode.parentNode.removeChild signatureNode
            # force update of React component
            @onHTMLChange()
        else if @refs.content?
            node = @refs.content.getDOMNode()
            oldSig = @props.accounts[oldProps.accountID].signature
            if signature? and signature.length > 0
                if oldSig and oldSig.length > 0
                    # replace old signature by new one
                    node.textContent = node.textContent.replace oldSig, signature
                else
                    # add signature at the end of message
                    node.textContent += "\n\n-- \n#{signature}"
            else
                # new account has no signature
                if oldSig and oldSig.length > 0
                    # delete old signature
                    oldSig = "-- \n#{signature}"
                    node.textContent = node.textContent.replace oldSig, ''
            # force update of React component
            @onTextChange()

    onKeyDown: (evt) ->
        if evt.ctrlKey and evt.key is 'Enter'
            @props.onSend()

    ###
    # Handle dropping of images inside editor
    ###
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
        # Add files to Compose file picker
        @props.getPicker().addFiles files
        if @props.composeInHTML
            for file in files
                # for every image, insert it into the HTML compose editor
                # Set the file name to data-src so it can be converted to cid: url on send
                # Convert the file to a data-uri to display the image inside the editor
                if file.type.split('/')[0] is 'image'
                    id  = "editor-img-#{new Date()}"
                    img = "<img data-src='#{file.name}' id='#{id}'>"
                    # if editor has not the focus, insert image at the end
                    # otherwise at cursor position
                    if not document.activeElement.classList.contains 'rt-editor'
                        # if there is a signature, insert image juste before
                        signature = document.getElementById 'signature'
                        if signature?
                            signature.previousElementSibling.innerHTML += img
                        else
                            document.querySelector('.rt-editor').innerHTML += img
                    else
                        document.execCommand 'insertHTML', false, img
                    FileUtils.fileToDataURI file, (result) =>
                        img = document.getElementById id
                        if img
                            img.removeAttribute 'id'
                            img.src = result
                            # force update of React component
                            @onHTMLChange()
        @setState target: false


    choosePhoto: (e) ->
        e.preventDefault()
        intent =
            type  : 'pickObject'
            params:
                objectType : 'singlePhoto'
                isCropped  : false
        timeout = 30000 # 30 seconds

        window.intentManager.send('nameSpace', intent, timeout)
            .then @choosePhoto_answer, (error) ->
                console.error 'response in error : ', error


    choosePhoto_answer : (message) ->
        answer = message.data
        if answer.newPhotoChosen
            data      = FileUtils.dataURItoBlob answer.dataUrl
            blob      = new Blob([data.blob, {type: data.mime}])
            blob.name = answer.name
            picker    = @props.getPicker()
            picker.addFiles [blob]
            if @props.composeInHTML
                if document.activeElement.classList.contains 'rt-editor'
                    # editor has focus, insert image at cursor position
                    document.execCommand('insertHTML', false, '<img src="' + answer.dataUrl + '" data-src="' + answer.name + '">')
                else
                    # otherwise, insert at end
                    # if there is a signature, insert image juste before
                    img = document.createElement 'img'
                    img.src = answer.dataUrl
                    img.dataset.src = answer.name
                    signature = document.getElementById 'signature'
                    if signature?
                        signature.parentNode.insertBefore img, signature
                    else
                        editor = document.querySelector('.rt-editor')
                        if editor?
                            editor.appendChild img
                # force update of React component
                @onHTMLChange()

