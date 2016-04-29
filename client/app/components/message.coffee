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

{MessageFlags, MessageActions} = require '../constants/app_constants'

LayoutActionCreator  = require '../actions/layout_action_creator'
NotificationActionsCreator = require '../actions/notification_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
ContactActionCreator = require '../actions/contact_action_creator'
RouterActionCreator = require '../actions/router_action_creator'

RGXP_PROTOCOL = /:\/\//


module.exports = React.createClass
    displayName: 'Message'

    prepareMessage: ->
        # display full headers
        fullHeaders = []
        for key, value of @props.message.get 'headers'
            value = value.join('\n ') if Array.isArray value
            fullHeaders.push "#{key}: #{value}"

        # Do not display content
        # if message isnt active
        if @props.active
            text = @props.message.get 'text'
            html = @props.message.get 'html'
            urls = /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/gim

            # Some calendar invitation
            # may contain neither text nor HTML part
            if not text? and not html?
                text = if (@props.message.get 'alternatives')?.length
                    t 'calendar unknown format'

            # TODO: Do we want to convert text only messages to HTML ?
            # /!\ if displayHTML is set, this method should always return
            # a value fo html, otherwise the content of the email flashes
            if text? and not html? and @props.displayHTML
                try
                    html = markdown.toHTML text.replace(/(^>.*$)([^>]+)/gm, "$1\n$2")
                    html = "<div class='textOnly'>#{html}</div>"
                catch e
                    html = "<div class='textOnly'>#{text}</div>"

            if html? and not text? and not @props.displayHTML
                text = toMarkdown html

            if text?
                rich = text.replace urls, '<a href="$1" target="_blank">$1</a>'
                rich = rich.replace /^>>>>>[^>]?.*$/gim, '<span class="quote5">$&</span>'
                rich = rich.replace /^>>>>[^>]?.*$/gim, '<span class="quote4">$&</span>'
                rich = rich.replace /^>>>[^>]?.*$/gim, '<span class="quote3">$&</span>'
                rich = rich.replace /^>>[^>]?.*$/gim, '<span class="quote2">$&</span>'
                rich = rich.replace /^>[^>]?.*$/gim, '<span class="quote1">$&</span>'

        flags = @props.message.get('flags').slice()
        mailboxes = @props.message.get 'mailboxIDs'
        trash = @props.trashMailbox
        return {
            attachments : @props.message.get 'attachments'
            fullHeaders : fullHeaders
            text        : text
            rich        : rich
            html        : html
            isDraft     : (flags.indexOf(MessageFlags.DRAFT) > -1)
            isDeleted   : mailboxes[trash]?
        }

    prepareHTML: (html) ->
        displayHTML = true
        parser = new DOMParser()
        html   = """<html><head>
                <link rel="stylesheet" href="./fonts/fonts.css" />
                <link rel="stylesheet" href="./mail_stylesheet.css" />
                <style>body { visibility: hidden; }</style>
            </head><body>#{html}</body></html>"""
        doc    = parser.parseFromString html, "text/html"
        images = []

        unless doc
            doc = document.implementation.createHTMLDocument("")
            doc.documentElement.innerHTML = html

        unless doc
            console.error "Unable to parse HTML content of message"
            displayHTML = false

        if doc and not @props.displayImages
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
            html = doc.documentElement.innerHTML

        return {displayHTML, images, html}

    isUnread: ->
        @props.message.get('flags').indexOf(MessageFlags.SEEN) is -1

    onHeaderClicked: ->
        messageID = @props.message.get 'id'
        mailboxID = @props.message.get 'mailboxID'
        RouterActionCreator.gotoMessage {messageID, mailboxID}

    render: ->
        message  = @props.message
        prepared = @prepareMessage()

        if @props.displayHTML and prepared.html?
            {displayHTML, images, html} = @prepareHTML prepared.html
            imagesWarning = images.length > 0 and not @props.displayImages
        else
            displayHTML = false
            imagesWarning = false
            html = ''

        classes = classNames
            message: true
            active: @props.active
            isDraft: prepared.isDraft
            isDeleted: prepared.isDeleted
            isUnread: @isUnread()

        article
            className: classes,
            key: @props.key,
            'data-message-active': @props.active
            'data-id': @props.message.get('id'),

                header onClick: @onHeaderClicked,
                    MessageHeader
                        message: @props.message
                        isDraft: prepared.isDraft
                        isDeleted: prepared.isDeleted
                        active: @props.active
                        ref: 'header'

                    if @props.active
                        @renderToolbox()

                if @props.active
                    div className: 'full-headers',
                        # should be a pre, but it breaks flex
                        textarea
                            disabled: true
                            resize: false
                            value: prepared?.fullHeaders?.join("\n")

                    MessageContent
                        ref: 'messageContent'
                        messageID: @props.message.get 'id'
                        displayHTML: @props.displayHTML
                        html: html
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
            selectedMailboxID    : @props.selectedMailboxID
            onDelete             : @onDelete
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
            messageID = @props.message.get 'id'
            accountID = @props.message.get 'accountID'
            MessageActionCreator.delete {messageID, accountID}

        unless @props.confirmDelete
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
        NotificationActionsCreator.alertWarning t "app unimplemented"


    addAddress: (address) ->
        ContactActionCreator.createContact address


    displayImages: (event) ->
        event.preventDefault()
        @setState displayImages: true


    displayHTML: (value) ->
        value = true unless value?
        @setState displayHTML: value
