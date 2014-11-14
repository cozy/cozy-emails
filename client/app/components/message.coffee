{div, ul, li, span, i, p, h3, a, button, pre, iframe, img} = React.DOM
Compose      = require './compose'
FilePicker   = require './file_picker'
MessageUtils = require '../utils/message_utils'
{ComposeActions, MessageFlags} = require '../constants/app_constants'
LayoutActionCreator       = require '../actions/layout_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'
ContactActionCreator      = require '../actions/contact_action_creator'
RouterMixin = require '../mixins/router_mixin'
Participants  = require './participant'

FlagsConstants =
    SEEN   : MessageFlags.SEEN
    UNSEEN : "Unseen"
    FLAGGED: MessageFlags.FLAGGED
    NOFLAG : "Noflag"

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
        if not (Immutable.is(nextState, @state))
            return true
        else
            props = Object.keys nextProps
            different = props.some (key) =>
                return not (Immutable.is(nextProps[key], @props[key]))
            return different

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

        # @TODO Do we want to convert text only messages to HTML ?
        #if text and not html and @state.messageDisplayHTML
        #    html = markdown.toHTML text

        if html and not text and not @state.messageDisplayHTML
            text = toMarkdown html

        return {
            id         : message.get('id')
            attachments: message.get('attachments') or []
            flags      : message.get('flags') or []
            from       : message.get('from')
            to         : message.get('to')
            cc         : message.get('cc')
            fullHeaders: fullHeaders
            text       : text
            html       : html
            date       : MessageUtils.formatDate message.get 'createdAt'
        }

    componentWillMount: ->
        @_markRead @props.message

    componentWillReceiveProps: (props) ->
        state =
            active: props.active
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
        html   = "<html><head></head><body>#{prepared.html}</body></html>"
        doc    = parser.parseFromString html, "text/html"
        images = []
        if not doc
            doc = document.implementation.createHTMLDocument("")
            doc.documentElement.innerHTML = html
        if not doc
            console.log "Unable to parse HTML content of message"
            messageDisplayHTML = false
        if doc and not @state.messageDisplayImages
            hideImage = (img) ->
                img.dataset.src = img.getAttribute 'src'
                img.removeAttribute 'src'
            images = doc.querySelectorAll 'IMG[src]'
            hideImage img for img in images
        if doc?
            @_htmlContent = doc.body.innerHTML
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
                    @renderToolbox message.get('id'), prepared
                    @renderHeaders prepared
                    div className: 'full-headers',
                        pre null, prepared.fullHeaders.join "\n"
                    if messageDisplayHTML and prepared.html
                        div className: 'row',
                            if imagesWarning
                                div
                                    className: "imagesWarning content-action",
                                    ref: "imagesWarning",
                                        span null, t 'message images warning'
                                        button
                                            className: 'btn btn-default',
                                            type: "button",
                                            ref: 'imagesDisplay',
                                            onClick: @displayImages,
                                            t 'message images display'
                            iframe
                                className: 'content',
                                ref: 'content',
                                sandbox: 'allow-same-origin',
                                allowTransparency: true,
                                frameBorder: 0,
                                name: "message-" + message.get('id'), ''
                    else
                        div className: 'row',
                            #div className: "content-action",
                            #    button
                            #       className: 'btn btn-default',
                            #       type: "button",
                            #       onClick: @displayHTML,
                            #       t 'message html display'
                            div className: 'preview',
                                p null, prepared.text
                    div className: 'clearfix'
                    @renderNavigation()

                    # Display Compose block
                    @renderCompose()
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
        # display attachment
        display = (file) ->
            window.open "/message/#{prepared.id}/attachments/#{file.name}"
        attachments = FilePicker
            editable: false
            value: prepared.attachments.map(MessageUtils.convertAttachments)
            display: display
        avatar = MessageUtils.getAvatar @props.message
        classes = classer
            'header': true
            'row': true
            'full': @state.headers
            'compact': not @state.headers
            'has-attachments': hasAttachments
            'is-fav': flags.indexOf(MessageFlags.FLAGGED) isnt -1

        toggleActive = a className: "toggle-active", onClick: @toggleActive,
            if @state.active
                i className: 'fa fa-compress'
            else
                i className: 'fa fa-expand'
        if @state.headers
            div className: classes,
                div className: leftClass, onClick: @toggleHeaders,
                    if avatar
                        img className: 'sender-avatar', src: avatar
                    else
                        i className: 'sender-avatar fa fa-user'
                    div className: 'participants col-md-9',
                        p className: 'sender',
                            @renderAddress 'from'
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
                        attachments
                if @props.inConversation
                    toggleActive
        else
            div className: classes, onClick: @toggleHeaders,
                if avatar
                    img className: 'sender-avatar', src: avatar
                else
                    i className: 'sender-avatar fa fa-user'
                span className: 'participants', @getParticipants prepared
                span className: 'subject', @props.message.get 'subject'
                span className: 'hour', prepared.date
                span className: "flags",
                    i className: 'attach fa fa-paperclip'
                    i className: 'fav fa fa-star'
                if @props.inConversation
                    toggleActive


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

    renderToolbox: (id, prepared) ->

        if @state.composing
            return

        isFlagged = prepared.flags.indexOf(FlagsConstants.FLAGGED) is -1
        isSeen    = prepared.flags.indexOf(FlagsConstants.SEEN) is -1

        div className: 'messageToolbox row',
            div className: 'btn-toolbar', role: 'toolbar',
                div className: 'btn-group btn-group-sm btn-group-justified',
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
                    #div className: 'btn-group btn-group-sm',
                    #    button
                    #        className: 'btn btn-default dropdown-toggle flags',
                    #        type: 'button',
                    #        'data-toggle': 'dropdown',
                    #        t 'mail action mark',
                    #            span className: 'caret'
                    #    ul className: 'dropdown-menu', role: 'menu',
                    #        if isSeen
                    #            li null,
                    #                a
                    #                    role: 'menuitem',
                    #                    onClick: @onMark,
                    #                    'data-value': FlagsConstants.SEEN,
                    #                    t 'mail mark read'
                    #        else
                    #            li null,
                    #                a role: 'menuitem',
                    #                onClick: @onMark,
                    #                'data-value': FlagsConstants.UNSEEN,
                    #                t 'mail mark unread'
                    #        if isFlagged
                    #            li null,
                    #                a
                    #                    role: 'menuitem',
                    #                    onClick: @onMark,
                    #                    'data-value': FlagsConstants.FLAGGED,
                    #                    t 'mail mark fav'
                    #        else
                    #            li null,
                    #                a
                    #                    role: 'menuitem',
                    #                    onClick: @onMark,
                    #                    'data-value': FlagsConstants.NOFLAG,
                    #                    t 'mail mark nofav'
                    div className: 'btn-group btn-group-sm',
                        button
                            className: 'btn btn-default dropdown-toggle move',
                            type: 'button',
                            'data-toggle': 'dropdown',
                            t 'mail action move',
                                span className: 'caret'
                        ul
                            className: 'dropdown-menu dropdown-menu-right',
                            role: 'menu',
                                @props.mailboxes.map (mailbox, key) =>
                                    @renderMailboxes mailbox, key
                                .toJS()
                    div className: 'btn-group btn-group-sm',
                        button
                            className: 'btn btn-default dropdown-toggle more',
                            type: 'button',
                            'data-toggle': 'dropdown',
                            t 'mail action more',
                                span className: 'caret'
                        ul className: 'dropdown-menu dropdown-menu-right', role: 'menu',
                            li
                                role: 'presentation',
                                t 'mail action mark'
                            if isSeen
                                li null,
                                    a
                                        role: 'menuitem',
                                        onClick: @onMark,
                                        'data-value': FlagsConstants.SEEN,
                                        t 'mail mark read'
                            else
                                li null,
                                    a role: 'menuitem',
                                    onClick: @onMark,
                                    'data-value': FlagsConstants.UNSEEN,
                                    t 'mail mark unread'
                            if isFlagged
                                li null,
                                    a
                                        role: 'menuitem',
                                        onClick: @onMark,
                                        'data-value': FlagsConstants.FLAGGED,
                                        t 'mail mark fav'
                            else
                                li null,
                                    a
                                        role: 'menuitem',
                                        onClick: @onMark,
                                        'data-value': FlagsConstants.NOFLAG,
                                        t 'mail mark nofav'
                            li role: 'presentation', className: 'divider'
                            li role: 'presentation',
                                a
                                    onClick: @onHeaders,
                                    'data-message-id': id,
                                    t 'mail action headers'
                            li role: 'presentation',
                                a
                                    onClick: @onConversation,
                                    'data-action' : 'delete',
                                    t 'mail action conversation delete'
                            li role: 'presentation',
                                a
                                    onClick: @onConversation,
                                    'data-action' : 'seen',
                                    t 'mail action conversation seen'
                            li role: 'presentation',
                                a
                                    onClick: @onConversation,
                                    'data-action' : 'unseen',
                                    t 'mail action conversation unseen'
                            li role: 'presentation', className: 'divider'
                            li
                                role: 'presentation',
                                t 'mail action conversation move'
                            @props.mailboxes.map (mailbox, key) =>
                                @renderMailboxes mailbox, key, true
                            .toJS()
                            li role: 'presentation', className: 'divider'

    renderNavigation: ->

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

        div className: 'messageNavigation row',
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
                    if nextUrl?
                        div className: 'btn-group btn-group-sm',
                            button
                                className: 'btn btn-default next',
                                type: 'button',
                                onClick: displayNext,
                                    a href: nextUrl,
                                        span className: 'fa fa-long-arrow-right'

    renderMailboxes: (mailbox, key, conversation) ->
        # Don't display current mailbox
        if mailbox.get('id') is @props.selectedMailboxID
            return
        pusher = ""
        pusher += "--" for j in [1..mailbox.get('depth')] by 1
        li role: 'presentation', key: key,
            a
                role: 'menuitem',
                onClick: @onMove,
                'data-value': key,
                'data-conversation': conversation,
                "#{pusher}#{mailbox.get 'label'}"

    _initFrame: ->
        # - resize the frame to the height of its content
        # - if images are not displayed, create the function to display them
        #   and resize the frame
        if @refs.content
            frame = @refs.content.getDOMNode()
            loadContent = =>
                doc = frame.contentDocument or frame.contentWindow.document
                if doc?
                    s = document.createElement 'style'
                    doc.head.appendChild(s)
                    font = "../fonts/sourcesanspro/SourceSansPro-Regular"
                    rules = [
                        """
                        @font-face{
                          font-family: 'Source Sans Pro';
                          font-weight: 400;
                          font-style: normal;
                          font-stretch: normal;
                          src: url('#{font}.eot') format('embedded-opentype'),
                               url('#{font}.otf.woff') format('woff'),
                               url('#{font}.otf') format('opentype'),
                               url('#{font}.ttf') format('truetype');
                        }
                        """,
                        "body {
                            font-family: 'Source Sans Pro';
                        }",
                        "blockquote {
                            margin-left: .5em;
                            padding-left: .5em;
                            border-left: 2px solid blue;
                        }"
                    ]
                    rules.forEach (rule, idx) ->
                        s.sheet.insertRule rule, idx
                    doc.body.innerHTML = @_htmlContent
                    rect = doc.body.getBoundingClientRect()
                    frame.style.height = "#{rect.height + 40}px"
                else
                    # try to display text only
                    @setState messageDisplayHTML: false

            frame.addEventListener 'load', loadContent
            loadContent()

    componentDidMount: ->
        @_initFrame()

    componentDidUpdate: ->
        @_initFrame()

    toggleHeaders: (e) ->
        e.preventDefault()
        e.stopPropagation()
        @setState headers: not @state.headers

    toggleActive: (e) ->
        e.preventDefault()
        e.stopPropagation()
        if @state.active
            @setState { active: false, headers: false }
        else
            @setState active: true

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
        alertSuccess = LayoutActionCreator.alertSuccess
        message      = @props.message
        if window.confirm(t 'mail confirm delete', {subject: message.get('subject')})
            MessageActionCreator.delete message, (error) =>
                if error?
                    alertError "#{t("message action delete ko")} #{error}"
                else
                    alertSuccess t "message action delete ok"
                    @displayNextMessage()

    onCopy: (args) ->
        LayoutActionCreator.alertWarning t "app unimplemented"

    onMove: (args) ->
        newbox = args.target.dataset.value
        alertError   = LayoutActionCreator.alertError
        alertSuccess = LayoutActionCreator.alertSuccess
        if args.target.dataset.conversation?
            conversationID = @props.message.get('conversationID')
            ConversationActionCreator.move conversationID, newbox, (error) =>
                if error?
                    alertError "#{t("conversation move ko")} #{error}"
                else
                    alertSuccess t "conversation move ok"
                    @displayNextMessage()
        else
            oldbox = @props.selectedMailboxID
            MessageActionCreator.move @props.message, oldbox, newbox, (error) =>
                if error?
                    alertError "#{t("message action move ko")} #{error}"
                else
                    alertSuccess t "message action move ok"
                    @displayNextMessage()

    onMark: (args) ->
        flags = @props.message.get('flags').slice()
        flag = args.target.dataset.value
        alertError   = LayoutActionCreator.alertError
        alertSuccess = LayoutActionCreator.alertSuccess
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
        alertError   = LayoutActionCreator.alertError
        alertSuccess = LayoutActionCreator.alertSuccess
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
                        alertError "#{t("conversation seen ok ")} #{error}"
                    else
                        alertSuccess t "conversation seen ko "
            when 'unseen'
                ConversationActionCreator.unseen id, (error) ->
                    if error?
                        alertError "#{t("conversation unseen ok")} #{error}"
                    else
                        alertSuccess t "conversation unseen ko"

    onHeaders: (event) ->
        event.preventDefault()
        messageId = event.target.dataset.messageId
        document.querySelector(".conversation [data-id='#{messageId}']")
            .classList.toggle('with-headers')

    displayHTML: (event) ->
        event.preventDefault()
        @setState messageDisplayHTML: true

    displayImages: (event) ->
        event.preventDefault()
        @setState messageDisplayImages: true

    addAddress: (address) ->
        ContactActionCreator.createContact address
