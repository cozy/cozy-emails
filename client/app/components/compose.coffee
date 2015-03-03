{div, h3, a, i, textarea, form, label, button, span, ul, li, input} = React.DOM
classer = React.addons.classSet

FilePicker = require './file_picker'
MailsInput = require './mails_input'

AccountPicker = require './account_picker'

{ComposeActions} = require '../constants/app_constants'

MessageUtils = require '../utils/message_utils'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

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
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->

        return unless @props.accounts

        onCancel = =>
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
        classCc    = if @state.cc.length is 0 then '' else ' shown'
        classBcc   = if @state.bcc.length is 0 then '' else ' shown'

        labelSend   = if @state.sending then t 'compose action sending' else t 'compose action send'
        focusEditor = Array.isArray(@state.to) and @state.to.length > 0 and @state.subject isnt ''

        div id: 'email-compose',
            if @props.layout isnt 'full'
                a onClick: toggleFullscreen, className: 'expand pull-right clickable',
                    i className: 'fa fa-arrows-h'
            else
                a onClick: toggleFullscreen, className: 'close-email pull-right clickable',
                    i className:'fa fa-compress'
            h3
                'data-message-id': @props.message?.get('id') or ''
                @state.subject or t 'compose'
            form className: 'form-compose',
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

                MailsInput
                    id: 'compose-bcc'
                    className: 'compose-bcc' + classBcc
                    valueLink: @linkState 'bcc'
                    label: t 'compose bcc'
                    placeholder: t 'compose bcc help'

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
                                        span className: 'fa fa-refresh fa-spin'
                                    else
                                        span className: 'fa fa-send'
                                    span null, labelSend
                            button
                                className: 'btn btn-cozy btn-save',
                                disable: if @state.saving then true else null
                                type: 'button', onClick: @onDraft,
                                    if @state.saving
                                        span className: 'fa fa-refresh fa-spin'
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

        # scroll compose window into view
        @getDOMNode().scrollIntoView()

        # Focus
        if not Array.isArray(@state.to) or @state.to.length is 0
            setTimeout ->
                document.getElementById('compose-to').focus()
            , 0

    componentDidMount: ->
        @_initCompose()

    #componentDidUpdate: ->
    #    @_initCompose()

    componentWillUnmount: ->
        if @_saveInterval
            window.clearInterval @_saveInterval
        #if @state.isDraft and @state.id?
        #    if not window.confirm(t 'compose confirm keep draft')
        #        MessageActionCreator.delete @state.id, (error) ->
        #            if error?
        #                LayoutActionCreator.alertError "#{t("message action delete ko")} #{error}"
        #            else
        #                LayoutActionCreator.notify t('compose draft deleted')

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
            state = MessageUtils.makeReplyMessage @props.selectedAccountLogin,
                @props.inReplyTo, @props.action, @props.settings.get('composeInHTML')
            state.accountID ?= @props.selectedAccountID

        state.sending = false
        state.saving  = false
        return state

    componentWillReceiveProps: (nextProps) ->
        if nextProps.message isnt @props.message
            @props.message = nextProps.message
            @setState @getInitialState()

    onDraft: (args) ->
        @_doSend true

    onSend: (args) ->
        @_doSend false

    _doSend: (isDraft) ->

        account = @props.accounts[@state.accountID]

        from =
            name: account.name or undefined
            address: account.login

        message =
            id          : @state.id
            accountID   : @state.accountID
            mailboxIDs  : @state.mailboxIDs
            from        : [from]
            to          : @state.to
            cc          : @state.cc
            bcc         : @state.bcc
            subject     : @state.subject
            isDraft     : isDraft
            attachments : @state.attachments

        valid = true
        if not isDraft
            if @state.to.length is 0 and @state.cc.length is 0 and @state.bcc.length is 0
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
                message.html = @state.html
                try
                    message.text = toMarkdown(message.html)
                catch
                    message.text = message.html?replace /<[^>]*>/gi, ''

                # convert HTML entities
                tmp = document.createElement 'div'
                tmp.innerHTML = message.text
                message.text = tmp.textContent
            else
                message.text = @state.text.trim()

            if not isDraft and @_saveInterval
                window.clearInterval @_saveInterval

            if isDraft
                @setState saving: true
            else
                @setState sending: true

            MessageActionCreator.send message, (error, message) =>
                if isDraft
                    @setState saving: false
                else
                    @setState sending: false
                if isDraft
                    msgKo = t "message action draft ko"
                    msgOk = t "message action draft ok"
                else
                    msgKo = t "message action sent ko"
                    msgOk = t "message action sent ok"
                if error?
                    LayoutActionCreator.alertError "#{msgKo} #{error}"
                else
                    LayoutActionCreator.notify msgOk, autoclose: true

                    if not @state.id?
                        MessageActionCreator.setCurrent message.id

                    @setState message

                    if not isDraft
                        if @props.callback?
                            @props.callback error
                        else
                            @redirect @buildClosePanelUrl @props.layout

    _autosave: ->
        @_doSend true

    onDelete: (args) ->
        subject = @props.message.get 'subject'
        if subject? and subject isnt ''
            confirmMessage = t 'mail confirm delete', {subject: @props.message.get('subject')}
        else
            confirmMessage = t 'mail confirm delete nosubject'
        if window.confirm confirmMessage
            MessageActionCreator.delete @props.message, (error) =>
                if error?
                    LayoutActionCreator.alertError "#{t("message action delete ko")} #{error}"
                else
                    if @props.callback
                        @props.callback()
                    else
                        @redirect
                            direction: 'first'
                            action: 'account.mailbox.messages'
                            parameters: [@props.selectedAccountID, @props.selectedMailboxID]
                            fullWidth: true

    onToggleCc: (e) ->
        toggle = (e) -> e.classList.toggle 'shown'
        toggle e for e in @getDOMNode().querySelectorAll '.compose-cc'

    onToggleBcc: (e) ->
        toggle = (e) -> e.classList.toggle 'shown'
        toggle e for e in @getDOMNode().querySelectorAll '.compose-bcc'


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
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

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
                className: "rt-editor form-control #{folded}",
                ref: 'html',
                contentEditable: true,
                onKeyDown: @onKeyDown,
                onInput: onHTMLChange,
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

            # Some DOM manipulation when replying inside the message.
            # When inserting a new line, we must close all blockquotes,
            # insert a blank line and then open again blockquotes
            jQuery('.rt-editor').on('keypress', (e) ->
                if e.keyCode is 13
                    # timeout to let the editor perform its own stuff
                    setTimeout ->
                        matchesSelector = document.documentElement.matches or
                              document.documentElement.matchesSelector or
                              document.documentElement.webkitMatchesSelector or
                              document.documentElement.mozMatchesSelector or
                              document.documentElement.oMatchesSelector or
                              document.documentElement.msMatchesSelector

                        target = document.getSelection().anchorNode
                        targetElement = target
                        while not (targetElement instanceof Element)
                            targetElement = targetElement.parentNode
                        if not target?
                            return
                        if matchesSelector? and not matchesSelector.call(targetElement, '.rt-editor blockquote *')
                            # we are not inside a blockquote, nothing to do
                            return

                        if target.lastChild?
                            target = target.lastChild
                            if target.previousElementSibling?
                                target = target.previousElementSibling
                        parent = target

                        # alternative 1
                        # we create 2 ranges, one from the begining of message
                        # to the caret position, the second from caret to the
                        # end. We then create fragments from the ranges and
                        # override message with first fragment, a blank line
                        # and second fragment
                        process = ->
                            current = parent
                            parent = parent?.parentNode
                        process()
                        process() while (parent? and
                            not parent.classList.contains 'rt-editor')
                        rangeBefore = document.createRange()
                        rangeBefore.setEnd target, 0
                        rangeBefore.setStartBefore parent.firstChild
                        rangeAfter = document.createRange()
                        if target.nextSibling?
                            # remove the BR the <enter> key probably inserted
                            rangeAfter.setStart target.nextSibling, 0
                        else
                            rangeAfter.setStart target, 0
                        rangeAfter.setEndAfter parent.lastChild
                        before = rangeBefore.cloneContents()
                        after = rangeAfter.cloneContents()
                        inserted = document.createElement 'p'
                        inserted.innerHTML = "<br />"
                        parent.innerHTML = ""
                        parent.appendChild before
                        parent.appendChild inserted
                        parent.appendChild after

                        ###
                        # alternative 2
                        # We move every node from the caret to the end of the
                        # message to a new DOM tree, then insert a blank line
                        # and the new tree
                        parent = target
                        p2 = null
                        p3 = null
                        process = ->
                            p3 = p2
                            current = parent
                            parent = parent.parentNode
                            p2 = parent.cloneNode false
                            if p3?
                                p2.appendChild p3
                            s = current.nextSibling
                            while s?
                                p2.appendChild(s.cloneNode(true))
                                s2 = s.nextSibling
                                parent.removeChild s
                                s = s2
                        process()
                        process() while (parent.parentNode? and
                            not parent.parentNode.classList.contains 'rt-editor')
                        after = p2
                        inserted = document.createElement 'p'
                        inserted.innerHTML = "<br />"
                        if parent.nextSibling
                            parent.parentNode.insertBefore inserted, parent.nextSibling
                            parent.parentNode.insertBefore after, parent.nextSibling
                        else
                            parent.parentNode.appendChild inserted
                            parent.parentNode.appendChild after
                        ###

                        setTimeout ->
                            inserted.focus()
                        , 0
                        sel = window.getSelection()
                        sel.collapse inserted, 0

                    , 0
            )
            # Allow to hide original message
            if document.querySelector('.rt-editor blockquote') and not document.querySelector('.rt-editor .originalToggle')
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
                        node.selectionStart = node.selectionEnd = node.value.length
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
