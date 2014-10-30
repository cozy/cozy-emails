{div, ul, li, span, i, p, h3, a, button, pre, iframe} = React.DOM
Compose      = require './compose'
FilePicker   = require './file_picker'
MessageUtils = require '../utils/message_utils'
{ComposeActions, MessageFlags} = require '../constants/app_constants'
LayoutActionCreator       = require '../actions/layout_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'
ContactActionCreator      = require '../actions/contact_action_creator'
RouterMixin = require '../mixins/router_mixin'

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
        message           : React.PropTypes.object.isRequired
        key               : React.PropTypes.number.isRequired
        selectedAccount   : React.PropTypes.object.isRequired
        selectedMailboxID : React.PropTypes.string.isRequired
        mailboxes         : React.PropTypes.object.isRequired
        settings          : React.PropTypes.object.isRequired
        accounts          : React.PropTypes.object.isRequired

    shouldComponentUpdate: (nextProps, nextState) ->

        same =
            JSON.stringify(nextState) is JSON.stringify(@state) and
            JSON.stringify(nextProps.message.toJSON()) is JSON.stringify(@props.message.toJSON()) and
            #Immutable.is(nextProps.message, @props.message) and
            Immutable.is(nextProps.key, @props.key) and
            Immutable.is(nextProps.selectedAccount, @props.selectedAccount) and
            Immutable.is(nextProps.selectedMailbox, @props.selectedMailbox) and
            Immutable.is(nextProps.mailboxes, @props.mailboxes) and
            Immutable.is(nextProps.settings, @props.settings) and
            Immutable.is(nextProps.accounts, @props.accounts)

        return not same

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
        @_markRead @props.message
        state =
            messageDisplayHTML:   props.settings.get 'messageDisplayHTML'
            messageDisplayImages: props.settings.get 'messageDisplayImages'
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

    render: ->

        message  = @props.message
        prepared = @_prepareMessage()
        messageDisplayHTML = @state.messageDisplayHTML
        images = []
        if messageDisplayHTML and prepared.html
            parser = new DOMParser()
            html = "<html><head></head><body>#{prepared.html}</body></html>"
            doc = parser.parseFromString html, "text/html"
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
                #htmluri = "data:text/html;charset=utf-8;base64,#{btoa(unescape(encodeURIComponent(doc.body.innerHTML)))}"

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
                        div null,
                            if images.length > 0 and not @state.messageDisplayImages
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
                        div null,
                            #div className: "content-action",
                            #    button className: 'btn btn-default', type: "button",
                            #       onClick: @displayHTML, t 'message html display'
                            div className: 'preview',
                                p null, prepared.text
                    div className: 'clearfix'

                    # Display Compose block
                    @renderCompose()
        else
            li
                className: classes,
                key: @props.key,
                'data-id': message.get('id'),
                    @renderHeaders prepared

    renderHeaders: (prepared) ->
        hasAttachments = prepared.attachments.length
        leftClass = if hasAttachments then 'col-md-8' else 'col-md-12'
        flags     = prepared.flags
        participants = """#{MessageUtils.displayAddresses prepared.from},
            #{MessageUtils.displayAddresses prepared.to}
            #{MessageUtils.displayAddresses prepared.cc}"""
        # display attachment
        display = (file) ->
            url = "/message/#{prepared.id}/attachments/#{file.name}"
            window.open url
        attachments = FilePicker
            editable: false
            value: prepared.attachments.map(MessageUtils.convertAttachments)
            display: display
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
                    i className: 'sender-avatar fa fa-user'
                    div className: 'participants',
                        p className: 'sender',
                            @renderAddress 'from'
                        p className: 'receivers',
                            span null, t "mail receivers"
                            @renderAddress 'to'
                        p className: 'receivers',
                            span null, t "mail receivers cc"
                            @renderAddress 'cc'
                    span className: 'hour', prepared.date
                if hasAttachments
                    div className: 'col-md-4',
                        attachments
                toggleActive
        else
            div className: classes, onClick: @toggleHeaders,
                i className: 'fa fa-user'
                span className: 'participants', participants
                span className: 'hour', prepared.date
                span className: "flags",
                    i className: 'attach fa fa-paperclip'
                    i className: 'fav fa fa-star'
                toggleActive


    renderAddress: (field) ->
        addresses = @props.message.get(field)
        if not addresses?
            return
        addresses = addresses.map (address, key) =>
            return {
                value: address
                addAddress: (e) =>
                    e.preventDefault()
                    e.stopPropagation()
                    @addAddress address
            }
        span null,
            addresses.map (address, key) ->
                span className: 'address', key: key,
                    span null, MessageUtils.displayAddress(address.value, true)
                    a className: 'address-add', onClick: address.addAddress,
                        i className: 'fa fa-plus'

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

        div className: 'messageToolbox',
            div className: 'btn-toolbar', role: 'toolbar',
                div className: 'btn-group btn-group-sm btn-group-justified',
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default', type: 'button', onClick: @onReply,
                            span className: 'fa fa-reply'
                            span className: 'tool-long', t 'mail action reply'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default', type: 'button', onClick: @onReplyAll,
                            span className: 'fa fa-reply-all'
                            span className: 'tool-long', t 'mail action reply all'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default', type: 'button', onClick: @onForward,
                            span className: 'fa fa-mail-forward'
                            span className: 'tool-long', t 'mail action forward'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default', type: 'button', onClick: @onDelete,
                            span className: 'fa fa-trash-o'
                            span className: 'tool-long', t 'mail action delete'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', t 'mail action mark',
                            span className: 'caret'
                        ul className: 'dropdown-menu', role: 'menu',
                            if prepared.flags.indexOf(FlagsConstants.SEEN) is -1
                                li null,
                                    a role: 'menuitem', onClick: @onMark, 'data-value': FlagsConstants.SEEN, t 'mail mark read'
                            else
                                li null,
                                    a role: 'menuitem', onClick: @onMark, 'data-value': FlagsConstants.UNSEEN, t 'mail mark unread'
                            if prepared.flags.indexOf(FlagsConstants.FLAGGED) is -1
                                li null,
                                    a role: 'menuitem', onClick: @onMark, 'data-value': FlagsConstants.FLAGGED, t 'mail mark fav'
                            else
                                li null,
                                    a role: 'menuitem', onClick: @onMark, 'data-value': FlagsConstants.NOFLAG, t 'mail mark nofav'
                            #li null,
                            #    a role: 'menuitem', onClick: @onMark, 'data-value': '', t 'mail mark spam'
                            #li null,
                            #    a role: 'menuitem', onClick: @onMark, 'data-value': '', t 'mail mark nospam'
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', t 'mail action move',
                            span className: 'caret'
                        ul className: 'dropdown-menu', role: 'menu',
                            @props.mailboxes.map (mailbox, key) =>
                                @renderMailboxes mailbox, key
                            .toJS()
                    div className: 'btn-group btn-group-sm',
                        button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown', t 'mail action more',
                            span className: 'caret'
                        ul className: 'dropdown-menu', role: 'menu',
                            li role: 'presentation',
                                a onClick: @onHeaders, 'data-message-id': id, t 'mail action headers'
                            li role: 'presentation',
                                a onClick: @onConversation, 'data-action' : 'delete', t 'mail action conversation delete'
                            li role: 'presentation',
                                a onClick: @onConversation, 'data-action' : 'seen',   t 'mail action conversation seen'
                            li role: 'presentation',
                                a onClick: @onConversation, 'data-action' : 'unseen', t 'mail action conversation unseen'
                            li role: 'presentation', className: 'divider'
                            li role: 'presentation', t 'mail action conversation move'
                            @props.mailboxes.map (mailbox, key) =>
                                @renderMailboxes mailbox, key, true
                            .toJS()
                            li role: 'presentation', className: 'divider'


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
                    font = """
@font-face{
  font-family: 'Source Sans Pro';
  font-weight: 400;
  font-style: normal;
  font-stretch: normal;
  src: url('../fonts/sourcesanspro/SourceSansPro-Regular.eot') format('embedded-opentype'),
       url('../fonts/sourcesanspro/SourceSansPro-Regular.otf.woff') format('woff'),
       url('../fonts/sourcesanspro/SourceSansPro-Regular.otf') format('opentype'),
       url('../fonts/sourcesanspro/SourceSansPro-Regular.ttf') format('truetype');
}
                """
                    s.sheet.insertRule font, 0
                    s.sheet.insertRule "body { font-family: 'Source Sans Pro'; }", 1
                    s.sheet.insertRule "blockquote { margin-left: .5em; padding-left: .5em; border-left: 2px solid blue;}", 2
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

    onReply: (args) ->
        @setState composing: true
        @setState composeAction: ComposeActions.REPLY

    onReplyAll: (args) ->
        @setState composing: true
        @setState composeAction: ComposeActions.REPLY_ALL

    onForward: (args) ->
        @setState composing: true
        @setState composeAction: ComposeActions.FORWARD

    onDelete: (args) ->
        if window.confirm(t 'mail confirm delete')
            MessageActionCreator.delete @props.message, @props.selectedAccount, (error) =>
                if error?
                    LayoutActionCreator.alertError "#{t("message action delete ko")} #{error}"
                else
                    LayoutActionCreator.alertSuccess t "message action delete ok"
                    @redirect
                        direction: 'first'
                        action: 'account.mailbox.messages'
                        parameters: [@props.selectedAccount.get('id'), @props.selectedMailboxID, 1]
                        fullWidth: true

    onCopy: (args) ->
        LayoutActionCreator.alertWarning t "app unimplemented"

    onMove: (args) ->
        newbox = args.target.dataset.value
        if args.target.dataset.conversation?
            ConversationActionCreator.move @props.message.get('conversationID'), newbox, (error) =>
                if error?
                    LayoutActionCreator.alertError "#{t("conversation move ko")} #{error}"
                else
                    LayoutActionCreator.alertSuccess t "conversation move ok"
                    @redirect
                        direction: 'first'
                        action: 'account.mailbox.messages'
                        parameters: [@props.selectedAccount.get('id'), @props.selectedMailboxID, 1]
                        fullWidth: true
        else
            oldbox = @props.selectedMailboxID
            MessageActionCreator.move @props.message, oldbox, newbox, (error) =>
                if error?
                    LayoutActionCreator.alertError "#{t("message action move ko")} #{error}"
                else
                    LayoutActionCreator.alertSuccess t "message action move ok"
                    @redirect
                        direction: 'first'
                        action: 'account.mailbox.messages'
                        parameters: [@props.selectedAccount.get('id'), @props.selectedMailboxID, 1]
                        fullWidth: true

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
                LayoutActionCreator.alertError "#{t("message action mark ko")} #{error}"
            else
                LayoutActionCreator.alertSuccess t "message action mark ok"

    onConversation: (args) ->
        id     = @props.message.get 'conversationID'
        action = args.target.dataset.action
        switch action
            when 'delete'
                ConversationActionCreator.delete id, (error) ->
                    if error?
                        LayoutActionCreator.alertError "#{t("conversation delete ko")} #{error}"
                    else
                        LayoutActionCreator.alertSuccess t "conversation delete ok"
            when 'seen'
                ConversationActionCreator.seen id, (error) ->
                    if error?
                        LayoutActionCreator.alertError "#{t("conversation seen ok ")} #{error}"
                    else
                        LayoutActionCreator.alertSuccess t "conversation seen ko "
            when 'unseen'
                ConversationActionCreator.unseen id, (error) ->
                    if error?
                        LayoutActionCreator.alertError "#{t("conversation unseen ok")} #{error}"
                    else
                        LayoutActionCreator.alertSuccess t "conversation unseen ko"

    onHeaders: (event) ->
        event.preventDefault()
        messageId = event.target.dataset.messageId
        document.querySelector(".conversation [data-id='#{messageId}']").classList.toggle('with-headers')

    displayHTML: (event) ->
        event.preventDefault()
        @setState messageDisplayHTML: true

    displayImages: (event) ->
        event.preventDefault()
        @setState messageDisplayImages: true

    addAddress: (address) ->
        ContactActionCreator.createContact address
