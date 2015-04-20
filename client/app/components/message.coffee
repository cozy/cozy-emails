{div, article, header, footer, ul, li, span, i, p, a, button, pre, iframe, img, h4} = React.DOM
MessageUtils = require '../utils/message_utils'

MessageHeader  = require "./message_header"
MessageFooter  = require "./message_footer"
ToolbarMessage = require './toolbar_message'
Compose        = require './compose'
Participants   = require './participant'

{ComposeActions, MessageFlags, FlagsConstants} = require '../constants/app_constants'

LayoutActionCreator       = require '../actions/layout_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'
ContactActionCreator      = require '../actions/contact_action_creator'

RouterMixin = require '../mixins/router_mixin'
TooltipRefresherMixin = require '../mixins/tooltip_refresher_mixin'

classer = React.addons.classSet
alertError   = LayoutActionCreator.alertError
alertSuccess = LayoutActionCreator.notify


module.exports = React.createClass
    displayName: 'Message'

    mixins: [
        RouterMixin
        TooltipRefresherMixin
    ]

    getInitialState: ->
        return {
            active: @props.active
            composing: @_shouldOpenCompose(@props)
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
        displayConversations   : React.PropTypes.bool
        key                    : React.PropTypes.string.isRequired
        mailboxes              : React.PropTypes.object.isRequired
        message                : React.PropTypes.object.isRequired
        selectedAccountID      : React.PropTypes.string.isRequired
        selectedAccountLogin   : React.PropTypes.string.isRequired
        selectedMailboxID      : React.PropTypes.string.isRequired
        settings               : React.PropTypes.object.isRequired

    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))
        return should

    _shouldOpenCompose: (props) ->
        # if message is a draft, and not deleted, open the compose component
        flags     = @props.message.get('flags').slice()
        trash     = @props.accounts[@props.selectedAccountID]?.trashMailbox
        isDraft   = flags.indexOf(MessageFlags.DRAFT) > -1
        isDeleted = @props.message.get('mailboxIDs')[trash]?
        return isDraft and not isDeleted

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

        # TODO: Do we want to convert text only messages to HTML ?
        # /!\ if messageDisplayHTML is set, this method should always return
        # a value fo html, otherwise the content of the email flashes
        if text? and not html? and @state.messageDisplayHTML
            try
                html = markdown.toHTML text.replace(/(^>.*$)([^>]+)/gm, "$1\n$2")
            catch e
                html = "<div class='text'>#{text}</div>" #markdown.toHTML text

        if html? and not text? and not @state.messageDisplayHTML
            text = toMarkdown html

        mailboxes = message.get 'mailboxIDs'
        trash = @props.accounts[@props.selectedAccountID]?.trashMailbox

        if text?
            rich = text.replace urls, '<a href="$1" target="_blank">$1</a>'
            rich = rich.replace /^>>>>>[^>]?.*$/gim, '<span class="quote5">$&</span>'
            rich = rich.replace /^>>>>[^>]?.*$/gim, '<span class="quote4">$&</span>'
            rich = rich.replace /^>>>[^>]?.*$/gim, '<span class="quote3">$&</span>'
            rich = rich.replace /^>>[^>]?.*$/gim, '<span class="quote2">$&</span>'
            rich = rich.replace /^>[^>]?.*$/gim, '<span class="quote1">$&</span>'

        flags = @props.message.get('flags').slice()
        return {
            attachments: message.get 'attachments'
            fullHeaders: fullHeaders
            text       : text
            rich       : rich
            html       : html
            isDraft    : (flags.indexOf(MessageFlags.DRAFT) > -1)
            isDeleted  : mailboxes[trash]?
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
            state.composing            = @_shouldOpenCompose props
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
            isDraft: prepared.isDraft
            isDeleted: prepared.isDeleted

        article
            className: classes,
            key: @props.key,
            'data-id': message.get('id'),
                header
                    onClick: => @setState active: not @state.active
                    @renderHeaders()
                    @renderToolbox() if @state.active
                @renderCompose(prepared.isDraft) if @state.active
                (div className: 'full-headers',
                    pre null, prepared?.fullHeaders?.join "\n") if @state.active
                (MessageContent
                    ref: 'messageContent'
                    messageID: message.get 'id'
                    messageDisplayHTML: messageDisplayHTML
                    html: @_htmlContent
                    text: prepared.text
                    rich: prepared.rich
                    imagesWarning: imagesWarning
                    composing: @state.composing
                    displayImages: @displayImages
                    displayHTML: @displayHTML) if @state.active
                (footer null,
                    @renderFooter()
                    @renderToolbox(false)) if @state.active

    getParticipants: (message) ->
        from = message.get 'from'
        to   = message.get('to').concat(message.get('cc'))
        span null,
            Participants
                participants: from
                onAdd: @addAddress
                tooltip: true
                ref: 'from'
            span null, ', '
            Participants
                participants: to
                onAdd: @addAddress
                tooltip: true
                ref: 'to'

    renderHeaders: ->
        MessageHeader
            message: @props.message
            isDraft: @state.prepared.isDraft
            isDeleted: @state.prepared.isDeleted
            ref: 'header'

    renderToolbox: (full = true) ->
        return if @state.composing

        ToolbarMessage
            full:              full
            message:           @props.message
            mailboxes:         @props.mailboxes
            selectedMailboxID: @props.selectedMailboxID
            onReply:           @onReply
            onReplyAll:        @onReplyAll
            onForward:         @onForward
            onDelete:          @onDelete
            onMove:            @onMove
            onHeaders:         @onHeaders
            ref:               'toolbarMessage'

    renderFooter: ->
        MessageFooter
            message: @props.message
            ref: 'footer'

    renderCompose: (isDraft) ->
        if @state.composing
            # If message is a draft, opens it, otherwise create a new message
            if isDraft
                Compose
                    layout               : 'second'
                    action               : null
                    inReplyTo            : null
                    settings             : @props.settings
                    accounts             : @props.accounts
                    selectedAccountID    : @props.selectedAccountID
                    selectedAccountLogin : @props.selectedAccountLogin
                    selectedMailboxID    : @props.selectedMailboxID
                    message              : @props.message
                    ref                  : 'compose'
            else
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
                            # component has probably already been unmounted due to conversation refresh
                            if @isMounted()
                                @setState composing: false
                    onCancel: =>
                        # component has probably already been unmounted due to conversation refresh
                        if @isMounted()
                            @setState composing: false

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
            if @props.displayConversations and nextConversationID?
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
        newbox  = args.target.dataset.value
        oldbox  = @props.selectedMailboxID
        subject = @props.message.get 'subject'
        if args.target.dataset.conversation?
            ConversationActionCreator.move @props.message, oldbox, newbox, (error) =>
                if error?
                    alertError "#{t("conversation move ko", subject: subject)} #{error}"
                else
                    alertSuccess t("conversation move ok", subject: subject)
                    @displayNextMessage()
        else
            MessageActionCreator.move @props.message, oldbox, newbox, (error) =>
                if error?
                    alertError "#{t("message action move ko", subject: subject)} #{error}"
                else
                    alertSuccess t("message action move ok", subject: subject)
                    @displayNextMessage()

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
            div null,
                if @props.imagesWarning
                    div
                        className: "imagesWarning alert alert-warning content-action",
                        ref: "imagesWarning",
                            i className: 'fa fa-shield'
                            t 'message images warning'
                            button
                                className: 'btn btn-xs btn-warning',
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
                div className: 'preview', ref: content,
                    p dangerouslySetInnerHTML: { __html: @props.rich }

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

    componentDidMount: ->
        @_initFrame('mount')

    componentDidUpdate: ->
        @_initFrame('update')
