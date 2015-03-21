{div, ul, li, span, i, p, a, button, pre, iframe, img, h4} = React.DOM
Compose        = require './compose'
FilePicker     = require './file_picker'
ToolboxActions = require './toolbox_actions'
ToolboxMove    = require './toolbox_move'
MessageUtils = require '../utils/message_utils'
{ComposeActions, MessageFlags, FlagsConstants} = require '../constants/app_constants'
LayoutActionCreator       = require '../actions/layout_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'
ContactActionCreator      = require '../actions/contact_action_creator'
RouterMixin = require '../mixins/router_mixin'
Participants  = require './participant'

classer = React.addons.classSet
alertError   = LayoutActionCreator.alertError
alertSuccess = LayoutActionCreator.notify

module.exports = React.createClass
    displayName: 'Message'

    mixins: [
        RouterMixin
    ]

    getInitialState: ->
        return {
            active: @props.active,
            composing: false
            composeAction: ''
            headers: false
            messageDisplayHTML:   @props.settings.get 'messageDisplayHTML'
            messageDisplayImages: @props.settings.get 'messageDisplayImages'
            currentMessageID: null
            prepared: {}
        }

    propTypes:
        accounts               : React.PropTypes.object.isRequired
        active                 : React.PropTypes.bool
        inConversation         : React.PropTypes.bool
        key                    : React.PropTypes.string.isRequired
        mailboxes              : React.PropTypes.object.isRequired
        message                : React.PropTypes.object.isRequired
        nextMessageID          : React.PropTypes.string
        nextConversationID     : React.PropTypes.string
        prevMessageID          : React.PropTypes.string
        prevConversationID     : React.PropTypes.string
        selectedAccountID      : React.PropTypes.string.isRequired
        selectedAccountLogin   : React.PropTypes.string.isRequired
        selectedMailboxID      : React.PropTypes.string.isRequired
        settings               : React.PropTypes.object.isRequired

    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))
        return should

    _prepareMessage: (message) ->
        # display full headers
        fullHeaders = []
        for key, value of message.get 'headers'
            if Array.isArray(value)
                fullHeaders.push "#{key}: #{value.join('\n    ')}"
            else
                fullHeaders.push "#{key}: #{value}"

        text = message.get 'text'
        html = message.get 'html'
        alternatives = message.get 'alternatives'
        urls = /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/gim
        # Some calendar invite may contain neither text nor HTML part
        if not text? and not html? and alternatives?.length > 0
            text = t 'calendar unknown format'

        #
        # @TODO Do we want to convert text only messages to HTML ?
        # /!\ if messageDisplayHTML is set, this method should always return
        # a value fo html, otherwise the content of the email flashes
        if text? and not html? and @state.messageDisplayHTML
            try
                html = markdown.toHTML text.replace(/(^>.*$)([^>]+)/gm, "$1\n$2")
            catch e
                html = "<div class='text'>#{text}</div>" #markdown.toHTML text

        if html? and not text? and not @state.messageDisplayHTML
            text = toMarkdown html

        if text?
            rich = text.replace urls, '<a href="$1" target="_blank">$1</a>'
            rich = rich.replace /^>>>>>[^>]?.*$/gim, '<span class="quote5">$&</span>'
            rich = rich.replace /^>>>>[^>]?.*$/gim, '<span class="quote4">$&</span>'
            rich = rich.replace /^>>>[^>]?.*$/gim, '<span class="quote3">$&</span>'
            rich = rich.replace /^>>[^>]?.*$/gim, '<span class="quote2">$&</span>'
            rich = rich.replace /^>[^>]?.*$/gim, '<span class="quote1">$&</span>'

        return {
            attachments: message.get 'attachments'
            fullHeaders: fullHeaders
            text       : text
            rich       : rich
            html       : html
        }

    componentWillMount: ->
        @_markRead @props.message

    componentWillReceiveProps: (props) ->
        state =
            active: props.active
        if props.message.get('id') isnt @props.message.get('id')
            @_markRead props.message
            state.messageDisplayHTML   = props.settings.get 'messageDisplayHTML'
            state.messageDisplayImages = props.settings.get 'messageDisplayImages'
            state.composing            = false
        @setState state

    _markRead: (message) ->
        # Hack to prevent infinite loop if server side mark as read fails
        messageID = message.get 'id'
        if @state.currentMessageID isnt messageID
            state =
                currentMessageID: messageID
                prepared: @_prepareMessage message
            # Mark message as seen if needed
            flags = message.get('flags').slice()
            if flags.indexOf(MessageFlags.SEEN) is -1
                flags.push MessageFlags.SEEN
                MessageActionCreator.updateFlag message, flags
            @setState state

    prepareHTML: (html) ->
        messageDisplayHTML = true
        parser = new DOMParser()
        html   = """<html><head>
                <link rel="stylesheet" href="/fonts/fonts.css" />
                <link rel="stylesheet" href="./mail_stylesheet.css" />
                <style>body { visibility: hidden; }</style>
            </head><body>#{html}</body></html>"""
        doc    = parser.parseFromString html, "text/html"
        images = []

        if not doc
            doc = document.implementation.createHTMLDocument("")
            doc.documentElement.innerHTML = html

        if not doc
            console.error "Unable to parse HTML content of message"
            messageDisplayHTML = false

        if doc and not @state.messageDisplayImages
            hideImage = (image) ->
                image.dataset.src = image.getAttribute 'src'
                image.removeAttribute 'src'
            images = doc.querySelectorAll 'IMG[src]'
            hideImage image for image in images

        for link in doc.querySelectorAll 'a[href]'
            link.target = '_blank'
            # convert relative to absolute links in message content
            href = link.getAttribute 'href'
            if href isnt '' and not /:\/\//.test href
                link.setAttribute 'href', 'http://' + href

        if doc?
            @_htmlContent = doc.documentElement.innerHTML
        else
            @_htmlContent = html

            #htmluri = "data:text/html;charset=utf-8;base64,
            #      #{btoa(unescape(encodeURIComponent(doc.body.innerHTML)))}"
        return {messageDisplayHTML, images}

    render: ->

        message  = @props.message
        prepared = @state.prepared

        if @state.messageDisplayHTML and prepared.html?
            {messageDisplayHTML, images} = @prepareHTML prepared.html
            imagesWarning = images.length > 0 and
                            not @state.messageDisplayImages
        else
            messageDisplayHTML = false
            imagesWarning      = false

        classes = classer
            message: true
            active: @state.active

        if @state.active
            li
                className: classes,
                key: @props.key,
                'data-id': message.get('id'),
                    @renderHeaders message
                    div className: 'full-headers',
                        pre null, prepared?.fullHeaders?.join "\n"
                    @renderToolbox message
                    @renderCompose()
                    MessageContent
                        ref: 'messageContent'
                        messageID: message.get 'id'
                        messageDisplayHTML: messageDisplayHTML
                        html: @_htmlContent
                        text: prepared.text
                        rich: prepared.rich
                        imagesWarning: imagesWarning
                        composing: @state.composing
                        displayImages: @displayImages
                        displayHTML: @displayHTML
                    @renderAttachments message.get('attachments').toJS()
                    div className: 'clearfix'
        else
            li
                className: classes,
                key: @props.key,
                'data-id': message.get('id'),
                    @renderHeaders message

    getParticipants: (message) ->
        from = message.get 'from'
        to   = message.get('to').concat(message.get('cc'))
        span null,
            Participants participants: from, onAdd: @addAddress, tooltip: true
            span null, ', '
            Participants participants: to, onAdd: @addAddress, tooltip: true

    renderHeaders: (message) ->
        attachments    = message.get('attachments')
        hasAttachments = attachments.length
        leftClass = if hasAttachments then 'col-md-8' else 'col-md-12'
        flags     = message.get('flags') or []
        avatar    = MessageUtils.getAvatar @props.message
        date      = MessageUtils.formatDate message.get 'createdAt'
        classes = classer
            'header': true
            'row': true
            'full': @state.headers
            'compact': not @state.headers
            'has-attachments': hasAttachments
            'is-fav': flags.indexOf(MessageFlags.FLAGGED) isnt -1

        #toggleActive = a className: "toggle-active", onClick: @toggleActive,
        #    if @state.active
        #        i className: 'fa fa-compress'
        #    else
        #        i className: 'fa fa-expand'
        if @state.headers
            # detailed headers
            div className: classes, onClick: @toggleActive,
                div className: leftClass,
                    if avatar
                        img className: 'sender-avatar', src: avatar
                    else
                        i className: 'sender-avatar fa fa-user'
                    div className: 'participants col-md-9',
                        p className: 'sender',
                            @renderAddress 'from'
                            i
                                className: 'toggle-headers fa fa-toggle-up clickable'
                                onClick: @toggleHeaders
                        p className: 'receivers',
                            span null, t "mail receivers"
                            @renderAddress 'to'
                        if @props.message.get('cc')?.length > 0
                            p className: 'receivers',
                                span null, t "mail receivers cc"
                                @renderAddress 'cc'
                        if hasAttachments
                            span className: 'hour', date
                    if not hasAttachments
                        span className: 'hour', date
                if hasAttachments
                    div className: 'col-md-4',
                        FilePicker
                            ref: 'filePicker'
                            editable: false
                            value: attachments
                            messageID: @props.message.get 'id'
                #if @props.inConversation
                #    toggleActive
        else
            # compact headers
            div className: classes, onClick: @toggleActive,
                if avatar
                    img className: 'sender-avatar', src: avatar
                else
                    i className: 'sender-avatar fa fa-user'
                span className: 'participants', @getParticipants message
                if @state.active
                    i
                        className: 'toggle-headers fa fa-toggle-down clickable'
                        onClick: @toggleHeaders
                #span className: 'subject', @props.message.get 'subject'
                span className: 'hour', date
                span className: "flags",
                    i
                        className: 'attach fa fa-paperclip clickable'
                        onClick: @toggleHeaders
                    i className: 'fav fa fa-star'
                #if @props.inConversation
                #    toggleActive


    renderAddress: (field) ->
        addresses = @props.message.get(field)
        if not addresses?
            return

        Participants participants: addresses, onAdd: @addAddress, tooltip: true

    renderCompose: ->
        if @state.composing
            Compose
                ref             : 'compose'
                inReplyTo       : @props.message
                accounts        : @props.accounts
                settings        : @props.settings
                selectedAccountID    : @props.selectedAccountID
                selectedAccountLogin : @props.selectedAccountLogin
                action          : @state.composeAction
                layout          : 'second'
                callback: (error) =>
                    if not error?
                        @setState composing: false
                onCancel: =>
                    @setState composing: false

    renderToolbox: (message) ->

        if @state.composing
            return

        flags     = message.get('flags') or []
        isFlagged = flags.indexOf(FlagsConstants.FLAGGED) is -1
        isSeen    = flags.indexOf(FlagsConstants.SEEN) is -1


        conversationID = @props.message.get 'conversationID'

        getParams = (messageID, conversationID) =>
            if @props.settings.get('displayConversation')
                return {
                    action : 'conversation'
                    parameters:
                        messageID : messageID
                        conversationID: conversationID
                }
            else
                return {
                    action : 'message'
                    parameters:
                        messageID : messageID
                }
        if @props.prevMessageID?
            params = getParams @props.prevMessageID, @props.prevConversationID
            prev =
                direction: 'second'
                action: params.action
                parameters: params.parameters
            prevUrl =  @buildUrl prev
            displayPrev = =>
                @redirect prev
        if @props.nextMessageID?
            params = getParams @props.nextMessageID, @props.nextConversationID
            next =
                direction: 'second'
                action: params.action
                parameters: params.parameters
            nextUrl = @buildUrl next
            displayNext = =>
                @redirect next

        div className: 'messageToolbox row',
            div className: 'btn-toolbar', role: 'toolbar',
                div className: 'btn-group btn-group-sm btn-group-justified',
                    if prevUrl?
                        div className: 'btn-group btn-group-sm',
                            button
                                className: 'btn btn-default prev',
                                type: 'button',
                                onClick: displayPrev,
                                    a href: prevUrl,
                                        span className: 'fa fa-long-arrow-left'
                    div className: 'btn-group btn-group-sm',
                        button
                            className: 'btn btn-default reply',
                            type: 'button',
                            onClick: @onReply,
                                span
                                    className: 'fa fa-reply'
                                span
                                    className: 'tool-long',
                                    t 'mail action reply'
                    div className: 'btn-group btn-group-sm',
                        button
                            className: 'btn btn-default reply-all',
                            type: 'button',
                            onClick: @onReplyAll,
                                span
                                    className: 'fa fa-reply-all'
                                span
                                    className: 'tool-long',
                                    t 'mail action reply all'
                    div className: 'btn-group btn-group-sm',
                        button
                            className: 'btn btn-default forward',
                            type: 'button',
                            onClick: @onForward,
                                span
                                    className: 'fa fa-mail-forward'
                                span
                                    className: 'tool-long',
                                    t 'mail action forward'
                    div className: 'btn-group btn-group-sm',
                        button
                            className: 'btn btn-default trash',
                            type: 'button',
                            onClick: @onDelete,
                                span
                                    className: 'fa fa-trash-o'
                                span
                                    className: 'tool-long',
                                    t 'mail action delete'
                    ToolboxMove
                        ref: 'toolboxMove'
                        mailboxes: @props.mailboxes
                        onMove: @onMove
                        direction: 'right'
                    ToolboxActions
                        ref: 'toolboxActions'
                        mailboxes: @props.mailboxes
                        isSeen: isSeen
                        isFlagged: isFlagged
                        mailboxID: @props.selectedMailboxID
                        messageID: message.get 'id'
                        message: @props.message
                        onMark: @onMark
                        onMove: @onMove
                        onConversation: @onConversation
                        onHeaders: @onHeaders
                        direction: 'right'
                    if nextUrl?
                        div className: 'btn-group btn-group-sm',
                            button
                                className: 'btn btn-default',
                                type: 'button',
                                onClick: displayNext,
                                    a href: nextUrl,
                                        span className: 'fa fa-long-arrow-right'

    renderAttachments: (attachments) ->
        files = attachments.filter (file) ->
            return MessageUtils.getAttachmentType(file.contentType) is 'image'
        if files.length is 0
            return

        div className: 'att-previews',
            h4 null, t 'message preview title'
            files.map (file) ->
                AttachmentPreview
                    ref: 'attachmentPreview'
                    file: file,
                    key: file.checksum

    toggleHeaders: (e) ->
        e.preventDefault()
        e.stopPropagation()
        state =
            headers: not @state.headers
        if @props.inConversation and not @state.active
            state.active = true
        @setState state

    toggleActive: (e) ->
        if @props.inConversation
            e.preventDefault()
            e.stopPropagation()
            if @state.active
                @setState { active: false, headers: false }
            else
                @setState { active: true, headers: false }

    displayNextMessage: ->
        if @props.nextMessageID?
            nextMessageID      = @props.nextMessageID
            nextConversationID = @props.nextConversationID
        else
            nextMessageID      = @props.prevMessageID
            nextConversationID = @props.prevConversationID
        if nextMessageID
            if @props.settings.get('displayConversation')
                @redirect
                    direction: 'second'
                    action : 'conversation'
                    parameters:
                        messageID : nextMessageID
                        conversationID: nextConversationID
            else
                @redirect
                    direction: 'second'
                    action : 'message'
                    parameters:
                        messageID : nextMessageID
        else
            @redirect
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters:
                    accountID: @props.message.get 'accountID'
                    mailboxID: @props.selectedMailboxID
                fullWidth: true

    onReply: (args) ->
        @setState composing: true, composeAction: ComposeActions.REPLY

    onReplyAll: (args) ->
        @setState composing: true, composeAction: ComposeActions.REPLY_ALL

    onForward: (args) ->
        @setState composing: true, composeAction: ComposeActions.FORWARD

    onDelete: (args) ->
        message      = @props.message
        if (not @props.settings.get('messageConfirmDelete')) or
        window.confirm(t 'mail confirm delete', {subject: message.get('subject')})
            @displayNextMessage()
            MessageActionCreator.delete message, (error) ->
                if error?
                    alertError "#{t("message action delete ko")} #{error}"

    onCopy: (args) ->
        LayoutActionCreator.alertWarning t "app unimplemented"

    onMove: (args) ->
        newbox = args.target.dataset.value
        oldbox = @props.selectedMailboxID
        if args.target.dataset.conversation?
            ConversationActionCreator.move @props.message, oldbox, newbox, (error) =>
                if error?
                    alertError "#{t("conversation move ko")} #{error}"
                else
                    alertSuccess t "conversation move ok"
                    @displayNextMessage()
        else
            MessageActionCreator.move @props.message, oldbox, newbox, (error) =>
                if error?
                    alertError "#{t("message action move ko")} #{error}"
                else
                    alertSuccess t "message action move ok"
                    @displayNextMessage()

    onMark: (args) ->
        flags = @props.message.get('flags').slice()
        flag = args.target.dataset.value
        switch flag
            when FlagsConstants.SEEN
                flags.push MessageFlags.SEEN
            when FlagsConstants.UNSEEN
                flags = flags.filter (e) -> return e isnt FlagsConstants.SEEN
            when FlagsConstants.FLAGGED
                flags.push MessageFlags.FLAGGED
            when FlagsConstants.NOFLAG
                flags = flags.filter (e) -> return e isnt FlagsConstants.FLAGGED
        MessageActionCreator.updateFlag @props.message, flags, (error) ->
            if error?
                alertError "#{t("message action mark ko")} #{error}"
            else
                alertSuccess t "message action mark ok"

    onConversation: (args) ->
        id     = @props.message.get 'conversationID'
        action = args.target.dataset.action
        switch action
            when 'delete'
                ConversationActionCreator.delete id, (error) ->
                    if error?
                        alertError "#{t("conversation delete ko")} #{error}"
                    else
                        alertSuccess t "conversation delete ok"
            when 'seen'
                ConversationActionCreator.seen id, (error) ->
                    if error?
                        alertError "#{t("conversation seen ko")} #{error}"
                    else
                        alertSuccess t "conversation seen ok"
            when 'unseen'
                ConversationActionCreator.unseen id, (error) ->
                    if error?
                        alertError "#{t("conversation unseen ko")} #{error}"
                    else
                        alertSuccess t "conversation unseen ok"

    onHeaders: (event) ->
        event.preventDefault()
        messageID = event.target.dataset.messageId
        document.querySelector(".conversation [data-id='#{messageID}']")
            .classList.toggle('with-headers')

    addAddress: (address) ->
        ContactActionCreator.createContact address

    displayImages: (event) ->
        event.preventDefault()
        @setState messageDisplayImages: true

    displayHTML: (value) ->
        if not value?
            value = true
        @setState messageDisplayHTML: value

MessageContent = React.createClass
    displayName: 'MessageContent'

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->
        displayHTML= =>
            @props.displayHTML true
        if @props.messageDisplayHTML and @props.html
            div className: 'row',
                if @props.imagesWarning
                    div
                        className: "imagesWarning content-action",
                        ref: "imagesWarning",
                            span null, t 'message images warning'
                            button
                                className: 'btn btn-default',
                                type: "button",
                                ref: 'imagesDisplay',
                                onClick: @props.displayImages,
                                t 'message images display'
                iframe
                    'data-message-id': @props.messageID
                    name: "frame-#{@props.messageID}"
                    className: 'content',
                    ref: 'content',
                    allowTransparency: true,
                    sandbox: 'allow-same-origin allow-popups',
                    frameBorder: 0
        else
            div className: 'row',
                #div className: "content-action",
                #    button
                #       className: 'btn btn-default',
                #       type: "button",
                #       onClick: @props.displayHTML,
                #       t 'message html display'
                div className: 'preview', ref: content,
                    p dangerouslySetInnerHTML: { __html: @props.rich }
                    #p null, @props.text

    _initFrame: (type) ->
        panel = document.querySelector "#panels > .panel:nth-of-type(2)"
        if panel? and not @props.composing
            panel.scrollTop = 0
        # - resize the frame to the height of its content
        # - if images are not displayed, create the function to display them
        #   and resize the frame
        if @props.messageDisplayHTML and @refs.content
            frame = @refs.content.getDOMNode()
            doc = frame.contentDocument or frame.contentWindow?.document
            checkResize = false # disabled for now
            step = 0
            # Function called on frame load
            # Inject HTML content of the message inside the frame, then
            # update frame height to remove scrollbar
            loadContent = (e) =>
                step = 0
                doc = frame.contentDocument or frame.contentWindow?.document
                if doc?
                    doc.documentElement.innerHTML = @props.html
                    window.cozyMails.customEvent "MESSAGE_LOADED", @props.messageID
                    updateHeight = (e) ->
                        height = doc.documentElement.scrollHeight
                        if height < 60
                            frame.style.height = "60px"
                        else
                            frame.style.height = "#{height + 60}px"
                        step++
                        # Prevent infinite loop on onresize event
                        if checkResize and step > 10

                            doc.body.removeEventListener 'load', loadContent
                            frame.contentWindow?.removeEventListener 'resize'

                    updateHeight()
                    # some browsers don't fire event when remote fonts are loaded
                    # so we need to wait a little and check the frame height again
                    setTimeout updateHeight, 1000

                    # Update frame height on load
                    doc.body.onload = updateHeight

                    # disabled for now
                    if checkResize
                        frame.contentWindow.onresize = updateHeight
                        window.onresize = updateHeight
                        frame.contentWindow?.addEventListener 'resize', updateHeight, true
                else
                    # try to display text only
                    @props.displayHTML false

            if type is 'mount' and doc.readyState isnt 'complete'
                frame.addEventListener 'load', loadContent
            else
                loadContent()
        else
            window.cozyMails.customEvent "MESSAGE_LOADED", @props.messageID

        if @refs.content? and not @props.composing
            @refs.content.getDOMNode().scrollIntoView()


    componentDidMount: ->
        @_initFrame('mount')

    componentDidUpdate: ->
        @_initFrame('update')

AttachmentPreview = React.createClass
    displayName: 'AttachmentPreview'

    getInitialState: ->
        return {
            displayed: false
        }

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->
        toggleDisplay = =>
            @setState displayed: not @state.displayed

        span
            className: 'att-preview',
            key: @props.key,
            if @state.displayed
                img
                    onClick: toggleDisplay
                    src: @props.file.url
            else
                button
                    className: 'btn btn-default btn-lg'
                    onClick: toggleDisplay
                    @props.file.generatedFileName
