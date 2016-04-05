React      = require 'react'
classNames = require 'classnames'

{markdown} = require 'markdown'
toMarkdown = require 'to-markdown'

{
    div, article, header, footer, ul, li, span, i, p, a, button, pre,
    iframe, textarea
} = React.DOM

MessageHeader  = React.createFactory require './message_header'
MessageFooter  = React.createFactory require './message_footer'
ToolbarMessage = React.createFactory require './toolbar_message'
MessageContent = React.createFactory require './message-content'

MessageStore = require '../stores/message_store'

{MessageFlags} = require '../constants/app_constants'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
ContactActionCreator = require '../actions/contact_action_creator'

RouterMixin           = require '../mixins/router_mixin'
ShouldComponentUpdate = require '../mixins/should_update_mixin'
TooltipRefresherMixin = require '../mixins/tooltip_refresher_mixin'

RGXP_PROTOCOL = /:\/\//


module.exports = React.createClass
    displayName: 'Message'

    mixins: [
        RouterMixin
        TooltipRefresherMixin
        ShouldComponentUpdate.UnderscoreEqualitySlow
    ]

    propTypes:
        accounts               : React.PropTypes.object.isRequired
        active                 : React.PropTypes.bool
        inConversation         : React.PropTypes.bool
        key                    : React.PropTypes.string.isRequired
        mailboxes              : React.PropTypes.object.isRequired
        message                : React.PropTypes.object.isRequired
        selectedAccountID      : React.PropTypes.string.isRequired
        selectedAccountLogin   : React.PropTypes.string.isRequired
        selectedMailboxID      : React.PropTypes.string.isRequired
        settings               : React.PropTypes.object.isRequired
        useIntents             : React.PropTypes.bool.isRequired
        toggleActive           : React.PropTypes.func.isRequired


    getInitialState: ->
        return {
            displayHeaders: false
            messageDisplayHTML: @props.settings.get 'messageDisplayHTML'
            messageDisplayImages: @props.settings.get 'messageDisplayImages'
            currentMessageID: null
            prepared: {}
        }


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
        if not text? and not html?
            # Some calendar invite may contain neither text nor HTML part
            if alternatives?.length > 0
                text = t 'calendar unknown format'
            else
                text = ''

        # TODO: Do we want to convert text only messages to HTML ?
        # /!\ if messageDisplayHTML is set, this method should always return
        # a value fo html, otherwise the content of the email flashes
        if text? and not html? and @state.messageDisplayHTML
            try
                html = markdown.toHTML text.replace(/(^>.*$)([^>]+)/gm, "$1\n$2")
                html = "<div class='textOnly'>#{html}</div>"
            catch e
                html = "<div class='textOnly'>#{text}</div>"

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
        @_markRead(@props.message, @props.active)


    componentWillReceiveProps: (props) ->
        state = {}
        if props.message.get('id') isnt @props.message.get('id')
            @_markRead(props.message, props.active)
            state.messageDisplayHTML   = props.settings.get 'messageDisplayHTML'
            state.messageDisplayImages = props.settings.get 'messageDisplayImages'
        @setState state


    _markRead: (message, active) ->
        # Hack to prevent infinite loop if server side mark as read fails
        messageID = message.get 'id'
        if @state.currentMessageID isnt messageID
            state =
                currentMessageID: messageID
                prepared: @_prepareMessage message
            @setState state

            # Only mark as read current active message if unseen
            flags = message.get('flags').slice()
            if active and flags.indexOf(MessageFlags.SEEN) is -1
                setTimeout ->
                    MessageActionCreator.mark {messageID}, MessageFlags.SEEN
                , 1


    prepareHTML: (html) ->
        messageDisplayHTML = true
        parser = new DOMParser()
        html   = """<html><head>
                <link rel="stylesheet" href="./fonts/fonts.css" />
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
            images = doc.querySelectorAll('IMG[src]')
            images = Array.prototype.filter.call images, (img) ->
                RGXP_PROTOCOL.test img.getAttribute('src')

            for image in images
                image.dataset.src = image.getAttribute 'src'
                image.removeAttribute 'src'

        for link in doc.querySelectorAll 'a[href]'
            link.target = '_blank'
            # convert relative to absolute links in message content
            href = link.getAttribute 'href'
            if href isnt '' and not RGXP_PROTOCOL.test href
                link.setAttribute 'href', 'http://' + href

        if doc?
            @_htmlContent = doc.documentElement.innerHTML
        else
            @_htmlContent = html

        return {messageDisplayHTML, images}

    isUnread: ->
        @props.message.get('flags').indexOf(MessageFlags.SEEN) is -1

    onHeaderClicked: ->
        messageID = @props.message.get('id')
        if @isUnread() and not @props.active
            MessageActionCreator.mark {messageID}, MessageFlags.SEEN
        @props.toggleActive messageID

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

        classes = classNames
            message: true
            active: @props.active
            isDraft: prepared.isDraft
            isDeleted: prepared.isDeleted
            isUnread: @isUnread()

        article
            className: classes,
            key: @props.key,
            'data-id': @props.message.get('id'),
                header onClick: @onHeaderClicked,
                    MessageHeader
                        message: @props.message
                        isDraft: @state.prepared.isDraft
                        isDeleted: @state.prepared.isDeleted
                        active: @props.active
                        ref: 'header'

                    if @props.active
                        @renderToolbox()

                if @props.active and @state.displayHeaders
                    div className: 'full-headers',
                        # should be a pre, but it breaks flex
                        textarea
                            disabled: true
                            resize: false
                            value: prepared?.fullHeaders?.join("\n")

                if @props.active
                    MessageContent
                        ref: 'messageContent'
                        messageID: message.get 'id'
                        messageDisplayHTML: messageDisplayHTML
                        html: @_htmlContent
                        text: prepared.text
                        rich: prepared.rich
                        imagesWarning: imagesWarning
                        displayImages: @displayImages
                        displayHTML: @displayHTML

                if @props.active
                    footer null,
                        MessageFooter
                            message: @props.message
                            ref: 'footer'
                        @renderToolbox(false)

    renderToolbox: (full = true) ->
        ToolbarMessage
            full                 : full
            message              : @props.message
            mailboxes            : @props.mailboxes
            selectedMailboxID    : @props.selectedMailboxID
            inConversation       : @props.inConversation
            onDelete             : @onDelete
            onHeaders            : @onHeaders
            onMove               : @onMove
            onMark               : @onMark
            onConversationDelete : @onConversationDelete
            onConversationMark   : @onConversationMark
            onConversationMove   : @onConversationMove
            ref                  : 'toolbarMessage'



    onDelete: (event) ->
        event.preventDefault()
        event.stopPropagation()

        success = =>
            # Get next focus conversation
            nextConversation = MessageStore.getPreviousConversation()
            nextConversation = MessageStore.getNextConversation() unless nextConversation.size

            # Then remove message
            MessageActionCreator.delete messageID: @state.currentMessageID

            unless nextConversation.size
                # Close 2nd panel : no next conversation found
                @redirect (url = @buildClosePanelUrl 'second')
            else
                # Goto to next conversation
                @redirect
                    direction: 'second',
                    action: 'conversation',
                    parameters:
                        messageID: nextConversation.get('id')
                        conversationID: nextConversation.get('conversationID')

        needConfirmation = @props.settings.get('messageConfirmDelete')
        unless needConfirmation
            success()
            return

        confirmMessage = t 'mail confirm delete',
            subject: @props.message.get('subject')
        LayoutActionCreator.displayModal
            title       : t 'app confirm delete'
            subtitle    : confirmMessage
            closeLabel  : t 'app cancel'
            actionLabel : t 'app confirm'
            action      : ->
                LayoutActionCreator.hideModal()
                success()

    onConversationDelete: ->
        conversationID = @props.message.get('conversationID')
        MessageActionCreator.delete {conversationID}


    onMark: (flag) ->
        messageID = @props.message.get('id')
        MessageActionCreator.mark {messageID}, flag


    onConversationMark: (flag) ->
        conversationID = @props.message.get('conversationID')
        MessageActionCreator.mark {conversationID}, flag


    onMove: (to) ->
        messageID = @props.message.get('id')
        from = @props.selectedMailboxID
        subject = @props.message.get 'subject'
        MessageActionCreator.move {messageID}, from, to


    onConversationMove: (to) ->
        conversationID = @props.message.get('conversationID')
        from = @props.selectedMailboxID
        subject = @props.message.get 'subject'
        MessageActionCreator.move {conversationID}, from, to


    onCopy: (args) ->
        LayoutActionCreator.alertWarning t "app unimplemented"


    onHeaders: (event) ->
        id = @props.message.get 'id'
        @setState displayHeaders: true

    addAddress: (address) ->
        ContactActionCreator.createContact address


    displayImages: (event) ->
        event.preventDefault()
        @setState messageDisplayImages: true


    displayHTML: (value) ->
        if not value?
            value = true
        @setState messageDisplayHTML: value
