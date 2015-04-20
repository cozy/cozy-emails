{div, h3, a, i, textarea, form, label, button} = React.DOM
{span, ul, li, input, img} = React.DOM

classer = React.addons.classSet

FilePicker = require './file_picker'
MailsInput = require './mails_input'

AccountPicker = require './account_picker'

{ComposeActions} = require '../constants/app_constants'

messageUtils = require '../utils/message_utils'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'

RouterMixin = require '../mixins/router_mixin'

module.exports = Compose = React.createClass
    displayName: 'Compose'

    mixins: [
        RouterMixin,
        React.addons.LinkedStateMixin # two-way data binding
    ]

    propTypes:
        selectedAccountID:    React.PropTypes.string.isRequired
        selectedAccountLogin: React.PropTypes.string.isRequired
        layout:               React.PropTypes.string.isRequired
        accounts:             React.PropTypes.object.isRequired
        message:              React.PropTypes.object
        action:               React.PropTypes.string
        callback:             React.PropTypes.func
        onCancel:             React.PropTypes.func
        settings:             React.PropTypes.object.isRequired

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))

    render: ->

        return unless @props.accounts

        onCancel = (e) =>
            e.preventDefault()
            if @props.onCancel?
                @props.onCancel()
            else
                @redirect @buildUrl
                    direction: 'first'
                    action: 'default'
                    fullWidth: true

        toggleFullscreen = ->
            LayoutActionCreator.toggleFullscreen()

        closeUrl = @buildClosePanelUrl @props.layout

        classLabel = 'compose-label'
        classInput = 'compose-input'
        classCc    = if @state.ccShown  then ' shown ' else ''
        classBcc   = if @state.bccShown then ' shown ' else ''

        if @state.sending
            labelSend = t 'compose action sending'
        else
            labelSend = t 'compose action send'
        focusEditor = Array.isArray(@state.to) and
            @state.to.length > 0 and
            @state.subject isnt ''

        div id: 'email-compose',
            if @props.layout isnt 'full'
                a
                    onClick: toggleFullscreen,
                    className: 'expand pull-right clickable',
                        i className: 'fa fa-arrows-h'
            else
                a
                    onClick: toggleFullscreen,
                    className: 'close-email pull-right clickable',
                        i className:'fa fa-compress'
            h3
                'data-message-id': @props.message?.get('id') or ''
                @state.subject or t 'compose'
            form className: 'form-compose', method: 'POST',
                div className: 'form-group account',
                    label
                        htmlFor: 'compose-from',
                        className: classLabel,
                        t "compose from"
                    div className: classInput,
                        div
                            className: 'btn-toolbar compose-toggle',
                            role: 'toolbar',
                                div null
                                    a
                                        className: 'compose-toggle-cc',
                                        onClick: @onToggleCc,
                                        t 'compose toggle cc'
                                    a
                                        className: 'compose-toggle-bcc',
                                        onClick: @onToggleBcc,
                                        t 'compose toggle bcc'

                        AccountPicker
                            accounts: @props.accounts
                            valueLink: @linkState 'accountID'
                div className: 'clearfix', null

                MailsInput
                    id: 'compose-to'
                    valueLink: @linkState 'to'
                    label: t 'compose to'
                    ref: 'to'

                MailsInput
                    id: 'compose-cc'
                    className: 'compose-cc' + classCc
                    valueLink: @linkState 'cc'
                    label: t 'compose cc'
                    placeholder: t 'compose cc help'
                    ref: 'cc'

                MailsInput
                    id: 'compose-bcc'
                    className: 'compose-bcc' + classBcc
                    valueLink: @linkState 'bcc'
                    label: t 'compose bcc'
                    placeholder: t 'compose bcc help'
                    ref: 'bcc'

                div className: 'form-group',
                    label
                        htmlFor: 'compose-subject',
                        className: classLabel,
                        t "compose subject"
                    div className: classInput,
                        input
                            id: 'compose-subject',
                            name: 'compose-subject',
                            ref: 'subject',
                            valueLink: @linkState('subject'),
                            type: 'text',
                            className: 'form-control',
                            placeholder: t "compose subject help"
                div className: '',
                    label
                        htmlFor: 'compose-subject',
                        className: classLabel,
                        t "compose content"
                    ComposeEditor
                        messageID: @props.message?.get 'id'
                        html: @linkState('html')
                        text: @linkState('text')
                        settings: @props.settings
                        onSend: @onSend
                        composeInHTML: @state.composeInHTML
                        focus: focusEditor
                        ref: 'editor'

                div className: 'attachements',
                    FilePicker
                        className: ''
                        editable: true
                        valueLink: @linkState 'attachments'
                        ref: 'attachments'

                div className: 'composeToolbox',
                    div className: 'btn-toolbar', role: 'toolbar',
                        div className: '',
                            button
                                className: 'btn btn-cozy btn-send',
                                type: 'button',
                                disable: if @state.sending then true else null
                                onClick: @onSend,
                                    if @state.sending
                                        span null,
                                            img
                                                src: 'images/spinner-white.svg'
                                                className: 'button-spinner'
                                    else
                                        span className: 'fa fa-send'
                                    span null, labelSend
                            button
                                className: 'btn btn-cozy btn-save',
                                disable: if @state.saving then true else null
                                type: 'button', onClick: @onDraft,
                                    if @state.saving
                                        span null,
                                            img
                                                src: 'images/spinner-white.svg'
                                                className: 'button-spinner'
                                    else
                                        span className: 'fa fa-save'
                                    span null, t 'compose action draft'
                            if @props.message?
                                button
                                    className: 'btn btn-cozy-non-default btn-delete',
                                    type: 'button',
                                    onClick: @onDelete,
                                        span className: 'fa fa-trash-o'
                                        span null, t 'compose action delete'
                            button
                                onClick: onCancel
                                className: 'btn btn-cozy-non-default btn-cancel',
                                t 'app cancel'

                div className: 'clearfix', null

    _initCompose: ->

        if @_saveInterval
            window.clearInterval @_saveInterval
        @_saveInterval = window.setInterval @_autosave, 30000
        # First save of draft
        @_autosave()

        # scroll compose window into view
        @getDOMNode().scrollIntoView()

        # Focus
        if not Array.isArray(@state.to) or @state.to.length is 0
            setTimeout ->
                document.getElementById('compose-to').focus()
            , 0

    componentDidMount: ->
        @_initCompose()

    componentDidUpdate: ->
        switch @state.focus
            when 'cc'
                setTimeout ->
                    document.getElementById('compose-cc').focus()
                , 0
                @setState focus: ''

            when 'bcc'
                setTimeout ->
                    document.getElementById('compose-bcc').focus()
                , 0
                @setState focus: ''

    componentWillUnmount: ->
        if @_saveInterval
            window.clearInterval @_saveInterval
        # If message has not been sent, ask if we sould keep it or not
        #  - if yes, and the draft belongs to a conversation, add the
        #    conversationID and save the draft
        #  - if no, delete the draft
        if @state.isDraft and
           @state.id?
            if not window.confirm(t 'compose confirm keep draft')
                window.setTimeout =>
                    MessageActionCreator.delete @state.id, (error) ->
                        if error?
                            LayoutActionCreator.alertError \
                                "#{t("message action delete ko")} #{error}"
                        else
                            LayoutActionCreator.notify t('compose draft deleted'),
                                autoclose: true
                , 0
            else
                if @state.originalConversationID?
                    # save one last time the draft, adding the conversationID
                    message =
                        id            : @state.id
                        accountID     : @state.accountID
                        mailboxIDs    : @state.mailboxIDs
                        from          : @state.from
                        to            : @state.to
                        cc            : @state.cc
                        bcc           : @state.bcc
                        subject       : @state.subject
                        isDraft       : true
                        attachments   : @state.attachments
                        inReplyTo     : @state.inReplyTo
                        references    : @state.references
                        text          : @state.text
                        html          : @state.html
                        conversationID: @state.originalConversationID
                    MessageActionCreator.send message, (error, message) ->
                        if error?
                            msg = "#{t "message action draft ko"} #{error}"
                            LayoutActionCreator.alertError msg
                        else
                            msg = "#{t "message action draft ok"}"
                            LayoutActionCreator.notify msg, autoclose: true
                            if message.conversationID?
                                # reload conversation to update its length
                                ConversationActionCreator.fetch message.conversationID

    getInitialState: (forceDefault) ->

        # edition of an existing draft
        if message = @props.message
            state =
                composeInHTML: @props.settings.get 'composeInHTML'
            if (not message.get('html')?) and message.get('text')
                state.conposeInHTML = false

            # TODO : smarter ?
            state[key] = value for key, value of message.toJS()
            # we want the immutable attachments
            state.attachments = message.get 'attachments'

        # new draft
        else
            state = messageUtils.makeReplyMessage @props.selectedAccountLogin,
                @props.inReplyTo, @props.action,
                @props.settings.get('composeInHTML')
            state.accountID ?= @props.selectedAccountID
            # use another field to prevent the empty conversationID of draft
            # to override the original conversationID
            state.originalConversationID = state.conversationID

        state.isDraft  = true
        state.sending  = false
        state.saving   = false
        state.ccShown  = Array.isArray(state.cc) and state.cc.length > 0
        state.bccShown = Array.isArray(state.bcc) and state.bcc.length > 0
        return state

    componentWillReceiveProps: (nextProps) ->
        if nextProps.message isnt @props.message
            @props.message = nextProps.message
            @setState @getInitialState()

    onDraft: (e) ->
        e.preventDefault()
        @_doSend true

    onSend: (e) ->
        if e?
            e.preventDefault()
        @_doSend false

    _doSend: (isDraft) ->

        account = @props.accounts[@state.accountID]

        from =
            name: account.name or undefined
            address: account.login

        message =
            id            : @state.id
            accountID     : @state.accountID
            mailboxIDs    : @state.mailboxIDs
            from          : [from]
            to            : @state.to
            cc            : @state.cc
            bcc           : @state.bcc
            subject       : @state.subject
            isDraft       : isDraft
            attachments   : @state.attachments
            inReplyTo     : @state.inReplyTo
            references    : @state.references

        if not isDraft
            # Add conversationID when sending message
            # we don't add conversationID to draft, otherwise the full
            # conversation would be updated, closing the compose panel
            message.conversationID = @state.originalConversationID

        valid = true
        if not isDraft
            if @state.to.length is 0 and
               @state.cc.length is 0 and
               @state.bcc.length is 0
                valid = false
                LayoutActionCreator.alertError t "compose error no dest"
                setTimeout ->
                    document.getElementById('compose-to').focus()
                , 0
            else if @state.subject is ''
                valid = false
                LayoutActionCreator.alertError t "compose error no subject"
                setTimeout =>
                    @refs.subject.getDOMNode().focus()
                , 0

        if valid
            if @state.composeInHTML
                message.html = @_cleanHTML @state.html
                message.text = messageUtils.cleanReplyText message.html
                message.html = messageUtils.wrapReplyHtml message.html
            else
                message.text = @state.text.trim()

            if not isDraft and @_saveInterval
                window.clearInterval @_saveInterval

            if isDraft
                @setState saving: true
            else
                @setState sending: true, isDraft: false

            MessageActionCreator.send message, (error, message) =>
                state = _.clone @state
                if isDraft
                    state.saving = false
                else
                    state.isDraft = false
                    state.sending = false
                state[key] = value for key, value of message
                # Sometime, when user cancel composing, the component has been
                # unmounted before we come back from autosave, and setState fails
                if @isMounted()
                    @setState state

                if isDraft
                    msgKo = t "message action draft ko"
                else
                    msgKo = t "message action sent ko"
                    msgOk = t "message action sent ok"
                if error?
                    LayoutActionCreator.alertError "#{msgKo} #{error}"
                else
                    # don't display confirmation message when draft has been saved
                    if not isDraft
                        LayoutActionCreator.notify msgOk, autoclose: true

                    if not @state.id?
                        MessageActionCreator.setCurrent message.id

                    if not isDraft
                        if message.conversationID?
                            # reload conversation to update its length
                            ConversationActionCreator.fetch message.conversationID
                        if @props.callback?
                            @props.callback error
                        else
                            @redirect @buildClosePanelUrl @props.layout

    _autosave: ->
        if @props.settings.get 'autosaveDraft'
            @_doSend true

    # set source of attached images
    _cleanHTML: (html) ->
        parser = new DOMParser()
        doc    = parser.parseFromString html, "text/html"

        if not doc
            doc = document.implementation.createHTMLDocument("")
            doc.documentElement.innerHTML = html

        if doc
            # the contentID of attached images will be in the data-src attribute
            # override image source with this attribute
            imageSrc = (image) ->
                image.setAttribute 'src', "cid:#{image.dataset.src}"
            images = doc.querySelectorAll 'IMG[data-src]'
            imageSrc image for image in images

            return doc.documentElement.innerHTML
        else
            console.error "Unable to parse HTML content of message"
            return html

    onDelete: (e) ->
        e.preventDefault()
        subject = @props.message.get 'subject'

        if subject? and subject isnt ''
            params = subject: @props.message.get 'subject'
            confirmMessage = t 'mail confirm delete', params

        else
            confirmMessage = t 'mail confirm delete nosubject'

        if window.confirm confirmMessage
            MessageActionCreator.delete @props.message, (error) =>

                if error?
                    msg = "#{t("message action delete ko")} #{error}"
                    LayoutActionCreator.alertError msg
                else

                    if @props.callback
                        @props.callback()
                    else
                        parameters = [
                            @props.selectedAccountID
                            @props.selectedMailboxID
                        ]

                        @redirect
                            direction: 'first'
                            action: 'account.mailbox.messages'
                            parameters: parameters
                            fullWidth: true

    onToggleCc: (e) ->
        toggle = (e) -> e.classList.toggle 'shown'
        toggle e for e in @getDOMNode().querySelectorAll '.compose-cc'
        focus = if not @state.ccShown then 'cc' else ''
        @setState ccShown: not @state.ccShown, focus: focus

    onToggleBcc: (e) ->
        toggle = (e) -> e.classList.toggle 'shown'
        toggle e for e in @getDOMNode().querySelectorAll '.compose-bcc'
        focus = if not @state.bccShown then 'bcc' else ''
        @setState bccShown: not @state.bccShown, focus: focus


ComposeEditor = React.createClass
    displayName: 'ComposeEditor'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]

    getInitialState: ->
        return {
            html: @props.html
            text: @props.text
        }

    componentWillReceiveProps: (nextProps) ->
        if nextProps.messageID isnt @props.messageID
            @setState html: nextProps.html, text: nextProps.text

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))

    render: ->

        onHTMLChange = (event) =>
            @props.html.requestChange @refs.html.getDOMNode().innerHTML

        onTextChange = (event) =>
            @props.text.requestChange @refs.content.getDOMNode().value

        if @props.settings.get 'composeOnTop'
            folded = 'folded'
        else
            folded = ''

        if @props.composeInHTML
            div
                className: "form-control rt-editor #{folded}",
                ref: 'html',
                contentEditable: true,
                onKeyDown: @onKeyDown,
                onInput: onHTMLChange,
                # when dropping an image, input is fired before the image has
                # really been added to the DOM, so we need to also listen to
                # blur event
                onBlur: onHTMLChange,
                dangerouslySetInnerHTML: {
                    __html: @state.html.value
                }
        else
            textarea
                className: 'editor',
                ref: 'content',
                onKeyDown: @onKeyDown,
                onChange: onTextChange,
                defaultValue: @state.text.value

    _initCompose: ->

        if @props.composeInHTML
            if @props.focus
                node = @refs.html?.getDOMNode()
                if not node?
                    return
                document.querySelector(".rt-editor").focus()
                if not @props.settings.get 'composeOnTop'
                    node.innerHTML += "<p><br /></p>"
                    node = node.lastChild
                    if node?
                        # move cursor to the bottom
                        node.scrollIntoView(false)
                        node.innerHTML = "<br \>"
                        s = window.getSelection()
                        r = document.createRange()
                        r.selectNodeContents(node)
                        s.removeAllRanges()
                        s.addRange(r)
                        document.execCommand('delete', false, null)
                        node.focus()


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

    componentDidMount: ->
        @_initCompose()

    componentDidUpdate: (nextProps, nextState) ->
        if nextProps.messageID isnt @props.messageID
            @_initCompose()

    onKeyDown: (evt) ->
        if evt.ctrlKey and evt.key is 'Enter'
            @props.onSend()
