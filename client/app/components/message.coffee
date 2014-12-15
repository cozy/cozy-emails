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
        }

    propTypes:
        accounts          : React.PropTypes.object.isRequired
        active            : React.PropTypes.bool
        inConversation    : React.PropTypes.bool
        key               : React.PropTypes.number.isRequired
        mailboxes         : React.PropTypes.object.isRequired
        message           : React.PropTypes.object.isRequired
        nextID            : React.PropTypes.string
        prevID            : React.PropTypes.string
        selectedAccount   : React.PropTypes.object.isRequired
        selectedMailboxID : React.PropTypes.string.isRequired
        settings          : React.PropTypes.object.isRequired

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    _prepareMessage: ->
        message = @props.message

        # display full headers
        fullHeaders = []
        for key, value of message.get 'headers'
            if Array.isArray(value)
                fullHeaders.push "#{key}: #{value.join('\n    ')}"
            else
                fullHeaders.push "#{key}: #{value}"

        text = message.get 'text'
        html = message.get 'html'
        urls = /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/gim
        # @TODO Do we want to convert text only messages to HTML ?
        # /!\ if messageDisplayHTML is set, this method should always return
        # a value fo html, otherwise the content of the email flashes
        if text and not html and @state.messageDisplayHTML
            html = markdown.toHTML text

        if html and not text and not @state.messageDisplayHTML
            text = toMarkdown html

        if text
            rich = text.replace urls, '<a href="$1" target="_blank">$1</a>', 'gim'
            rich = rich.replace(/^>>>>>[^>]?.*$/gim, '<span class="quote5">$&</span>')
            rich = rich.replace(/^>>>>[^>]?.*$/gim, '<span class="quote4">$&</span>')
            rich = rich.replace(/^>>>[^>]?.*$/gim, '<span class="quote3">$&</span>')
            rich = rich.replace(/^>>[^>]?.*$/gim, '<span class="quote2">$&</span>')
            rich = rich.replace(/^>[^>]?.*$/gim, '<span class="quote1">$&</span>', 'gim')

        return {
            id         : message.get('id')
            attachments: message.get('attachments')
            flags      : message.get('flags') or []
            from       : message.get('from')
            to         : message.get('to')
            cc         : message.get('cc')
            fullHeaders: fullHeaders
            text       : text
            rich       : rich
            html       : html
            date       : MessageUtils.formatDate message.get 'createdAt'
        }

    componentWillMount: ->
        @_markRead @props.message

    componentWillReceiveProps: (props) ->
        state =
            active: props.active
            composing: false
        if props.message.get('id') isnt @props.message.get('id')
            @_markRead @props.message
            state.messageDisplayHTML   = props.settings.get 'messageDisplayHTML'
            state.messageDisplayImages = props.settings.get 'messageDisplayImages'
        @setState state

    _markRead: (message) ->
        # Hack to prevent infinite loop if server side mark as read fails
        if @_currentMessageId is message.get 'id'
            return
        @_currentMessageId = message.get 'id'

        # Mark message as seen if needed
        flags = message.get('flags').slice()
        if flags.indexOf(MessageFlags.SEEN) is -1
            flags.push MessageFlags.SEEN
            MessageActionCreator.updateFlag message, flags

    prepareHTML: (prepared) ->
        messageDisplayHTML = true
        parser = new DOMParser()
        html   = """<html><head>
                <link rel="stylesheet" href="./mail_stylesheet.css" />
                <style>body { visibility: hidden; }</style>
            </head><body>#{prepared.html}</body></html>"""
        doc    = parser.parseFromString html, "text/html"
        images = []

        if not doc
            doc = document.implementation.createHTMLDocument("")
            doc.documentElement.innerHTML = html

        if not doc
            console.log "Unable to parse HTML content of message"
            messageDisplayHTML = false

        if doc and not @state.messageDisplayImages
            hideImage = (image) ->
                image.dataset.src = image.getAttribute 'src'
                image.removeAttribute 'src'
            images = doc.querySelectorAll 'IMG[src]'
            hideImage image for image in images

        for link in doc.querySelectorAll 'a[href]'
            link.target = '_blank'

        if doc?
            @_htmlContent = doc.documentElement.innerHTML
        else
            @_htmlContent = prepared.html

            #htmluri = "data:text/html;charset=utf-8;base64,
            #      #{btoa(unescape(encodeURIComponent(doc.body.innerHTML)))}"
        return {messageDisplayHTML, images}

    render: ->

        message  = @props.message
        prepared = @_prepareMessage()

        if @state.messageDisplayHTML and prepared.html
            {messageDisplayHTML, images} = @prepareHTML prepared
            imagesWarning = images.length > 0 and
                            not @state.messageDisplayImages

        classes = classer
            message: true
            active: @state.active

        if @state.active
            li
                className: classes,
                key: @props.key,
                'data-id': message.get('id'),
                    @renderHeaders prepared
                    div className: 'full-headers',
                        pre null, prepared.fullHeaders.join "\n"
                    @renderToolbox message.get('id'), prepared
                    @renderCompose()
                    MessageContent
                        message: message
                        messageDisplayHTML: messageDisplayHTML
                        html: @_htmlContent
                        text: prepared.text
                        rich: prepared.rich
                        imagesWarning: imagesWarning
                        composing: @state.composing
                        displayImages: @displayImages
                        displayHTML: @displayHTML
                    @renderAttachments prepared.attachments.toJS()
                    div className: 'clearfix'
        else
            li
                className: classes,
                key: @props.key,
                'data-id': message.get('id'),
                    @renderHeaders prepared

    getParticipants: (prepared) ->
        from = prepared.from
        to   = prepared.to.concat(prepared.cc)
        span null,
            Participants participants: from, onAdd: @addAddress
            span null, ', '
            Participants participants: to, onAdd: @addAddress

    renderHeaders: (prepared) ->
        hasAttachments = prepared.attachments.length
        leftClass = if hasAttachments then 'col-md-8' else 'col-md-12'
        flags     = prepared.flags
        avatar = MessageUtils.getAvatar @props.message
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
                                className: 'toggle-headers fa fa-toggle-up'
                                onClick: @toggleHeaders
                        p className: 'receivers',
                            span null, t "mail receivers"
                            @renderAddress 'to'
                        if @props.message.get('cc')?length > 0
                            p className: 'receivers',
                                span null, t "mail receivers cc"
                                @renderAddress 'cc'
                        if hasAttachments
                            span className: 'hour', prepared.date
                    if not hasAttachments
                        span className: 'hour', prepared.date
                if hasAttachments
                    div className: 'col-md-4',
                        FilePicker
                            editable: false
                            value: prepared.attachments
                #if @props.inConversation
                #    toggleActive
        else
            # compact headers
            div className: classes, onClick: @toggleActive,
                if avatar
                    img className: 'sender-avatar', src: avatar
                else
                    i className: 'sender-avatar fa fa-user'
                span className: 'participants', @getParticipants prepared
                if @state.active
                    i
                        className: 'toggle-headers fa fa-toggle-down'
                        onClick: @toggleHeaders
                #span className: 'subject', @props.message.get 'subject'
                span className: 'hour', prepared.date
                span className: "flags",
                    i className: 'attach fa fa-paperclip'
                    i className: 'fav fa fa-star'
                #if @props.inConversation
                #    toggleActive


    renderAddress: (field) ->
        addresses = @props.message.get(field)
        if not addresses?
            return

        Participants participants: addresses, onAdd: @addAddress

    renderCompose: ->
        if @state.composing
            Compose
                inReplyTo       : @props.message
                accounts        : @props.accounts
                settings        : @props.settings
                selectedAccount : @props.selectedAccount
                action          : @state.composeAction
                layout          : 'second'
                callback: (error) =>
                    if not error?
                        @setState composing: false
                onCancel: =>
                    @setState composing: false

    renderToolbox: (id, prepared) ->

        if @state.composing
            return

        isFlagged = prepared.flags.indexOf(FlagsConstants.FLAGGED) is -1
        isSeen    = prepared.flags.indexOf(FlagsConstants.SEEN) is -1


        conversationID = @props.message.get 'conversationID'

        getParams = (id) =>
            if conversationID and @props.settings.get('displayConversation')
                return {
                    action : 'conversation'
                    id     : id
                }
            else
                return {
                    action : 'message'
                    id     : id
                }
        if @props.prevID?
            params = getParams @props.prevID
            prev =
                direction: 'second'
                action: params.action
                parameters: params.id
            prevUrl =  @buildUrl prev
            displayPrev = =>
                @redirect prev
        if @props.nextID?
            params = getParams @props.nextID
            next =
                direction: 'second'
                action: params.action
                parameters: params.id
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
                        mailboxes: @props.mailboxes
                        onMove: @onMove
                        direction: 'right'
                    ToolboxActions
                        mailboxes: @props.mailboxes
                        isSeen: isSeen
                        isFlagged: isFlagged
                        messageID: id
                        onMark: @onMark
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
        files = attachments.filter (file) -> return MessageUtils.getAttachmentType(file.contentType) is 'image'
        if files.length is 0
            return

        div className: 'att-previews',
            h4 null, t 'message preview title'
            files.map (file) ->
                AttachmentPreview file: file, key: file.checksum

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

    displayNextMessage: (next)->
        if not next?
            if @props.nextID?
                next = @props.nextID
            else next = @props.prevID
        if next?
            @redirect
                direction: 'second'
                action: 'message'
                parameters: next
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
        alertError   = LayoutActionCreator.alertError
        message      = @props.message
        if @props.nextID?
            next = @props.nextID
        else next = @props.prevID
        if (not @props.settings.get('messageConfirmDelete')) or
        window.confirm(t 'mail confirm delete', {subject: message.get('subject')})
            @displayNextMessage next
            MessageActionCreator.delete message, (error) ->
                if error?
                    alertError "#{t("message action delete ko")} #{error}"

    onCopy: (args) ->
        LayoutActionCreator.alertWarning t "app unimplemented"

    onMove: (args) ->
        newbox = args.target.dataset.value
        alertError   = LayoutActionCreator.alertError
        if @props.nextID?
            next = @props.nextID
        else next = @props.prevID
        if args.target.dataset.conversation?
            conversationID = @props.message.get('conversationID')
            ConversationActionCreator.move conversationID, newbox, (error) =>
                if error?
                    alertError "#{t("conversation move ko")} #{error}"
                else
                    @displayNextMessage next
        else
            oldbox = @props.selectedMailboxID
            MessageActionCreator.move @props.message, oldbox, newbox, (error) =>
                if error?
                    alertError "#{t("message action move ko")} #{error}"
                else
                    @displayNextMessage next

    onMark: (args) ->
        flags = @props.message.get('flags').slice()
        flag = args.target.dataset.value
        alertError   = LayoutActionCreator.alertError
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

    onConversation: (args) ->
        id     = @props.message.get 'conversationID'
        action = args.target.dataset.action
        alertError   = LayoutActionCreator.alertError
        switch action
            when 'delete'
                ConversationActionCreator.delete id, (error) ->
                    if error?
                        alertError "#{t("conversation delete ko")} #{error}"

            when 'seen'
                ConversationActionCreator.seen id, (error) ->
                    if error?
                        alertError "#{t("conversation seen ok ")} #{error}"

            when 'unseen'
                ConversationActionCreator.unseen id, (error) ->
                    if error?
                        alertError "#{t("conversation unseen ok")} #{error}"

    onHeaders: (event) ->
        event.preventDefault()
        messageId = event.target.dataset.messageId
        document.querySelector(".conversation [data-id='#{messageId}']")
            .classList.toggle('with-headers')

    addAddress: (address) ->
        ContactActionCreator.createContact address

    displayImages: (event) ->
        event.preventDefault()
        @setState messageDisplayImages: true

    displayHTML: (event) ->
        event.preventDefault()
        @setState messageDisplayHTML: true

MessageContent = React.createClass
    displayName: 'MessageContent'

    getInitialState: ->
        return {
            messageDisplayHTML: @props.messageDisplayHTML
        }

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->
        if @state.messageDisplayHTML and @props.html
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
                    'data-message-id': @props.message.get 'id'
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
                div className: 'preview',
                    p dangerouslySetInnerHTML: { __html: @props.rich }
                    #p null, @props.text

    _initFrame: (type) ->
        panel = document.querySelector "#panels > .panel:nth-of-type(2)"
        if panel? and not @props.composing
            panel.scrollTop = 0
        # - resize the frame to the height of its content
        # - if images are not displayed, create the function to display them
        #   and resize the frame
        if @refs.content
            frame = @refs.content.getDOMNode()
            doc = frame.contentDocument or frame.contentWindow?.document
            step = 0
            loadContent = (e) =>
                step = 0
                doc = frame.contentDocument or frame.contentWindow?.document
                if doc?
                    doc.documentElement.innerHTML = @props.html
                    updateHeight = (e) ->
                        height = doc.body.getBoundingClientRect().height
                        frame.style.height = "#{height + 60}px"
                        step++
                        # In Chrome, onresize loops
                        if step > 10

                            doc.body.removeEventListener 'load', loadContent
                            frame.contentWindow?.removeEventListener 'resize'

                    frame.style.height = "32px"
                    updateHeight()
                    doc.body.onload = updateHeight
                    #frame.contentWindow.onresize = updateHeight
                    window.onresize = updateHeight
                    # In Chrome, addEventListener is forbidden by iframe sandboxing
                    #doc.body.addEventListener 'load', updateHeight, true
                    #frame.contentWindow?.addEventListener 'resize', updateHeight, true
                else
                    # try to display text only
                    @setState messageDisplayHTML: false

            if type is 'mount' and doc.readyState isnt 'complete'
                frame.addEventListener 'load', loadContent
            else
                loadContent()
        else
            console.warn "No ref.content"

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
                    @props.file.fileName
