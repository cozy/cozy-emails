React      = require 'react'
{span} = React.DOM

{markdown} = require 'markdown'
toMarkdown = require 'to-markdown'

Immutable   = require 'immutable'
moment      = require 'moment'
_           = require 'underscore'
jQuery      = require 'jquery'


{MessageActions, MessageFlags} = require '../constants/app_constants'

SettingsStore    = require '../stores/settings_store'

ContactGetter     = require '../getters/contact'

QUOTE_STYLE = "margin-left: 0.8ex; padding-left: 1ex; border-left: 3px solid #34A6FF;"

# Style is required to clean pre and p styling in compose editor.
# It is removed by the visulasation iframe that's why we need to put
# style at the p level too.
COMPOSE_STYLE = """
<style>
pre {background: transparent; border: 0}
</style>
"""

module.exports =

    # Display date as a readable string.
    # Make it shorter if compact is set to true.
    getCreatedAt: (message) ->
        return unless (date = message?.get 'createdAt')?

        today = moment()
        date  = moment date

        if date.isBefore today, 'year'
            formatter = 'DD/MM/YYYY'
        else if date.isBefore today, 'day'
            formatter = 'MMM DD'
        else
            formatter = 'HH:mm'

        return date.format formatter


    # Build message to put in the email composer depending on the context
    # (reply, reply to all, forward or simple message).
    # It add appropriate headers to the message. It adds style tags when
    # required too.
    # It adds signature at the end of the zone where the user will type.
    createBasicMessage: (props) ->
        props = _.clone props

        account =
            id: props.account?.get 'id'
            name: props.account?.get 'name'
            address: props.account?.get 'login'
            signature: props.account?.get 'signature'

        composeInHTML = props.settings.get 'composeInHTML'
        message =
            id              : props.id
            attachments     : Immutable.List()
            accountID       : account.id
            isDraft         : true
            composeInHTML   : false
            from            : [name: account.name, address: account.address]

        # edition of an existing draft
        if (_message = props.message)
            props.action = MessageActions.EDIT unless props.action
            _.extend message, _message.toJS()
            message.attachments = _message.get 'attachments'

        # Format text
        {text, html} = _cleanContent message

        if (inReplyTo = props.inReplyTo)
            replyID = inReplyTo.get 'id'
            html = inReplyTo?.get 'html'
            _.extend message,
                inReplyTo: inReplyTo
                references: (inReplyTo.get('references') or []).concat replyID

        signature = account.signature
        isSignature = !!!_.isEmpty signature
        dateHuman = moment(message.createdAt).format 'lll'
        sender = ContactGetter.displayAddresses message.from
        options = {
            message
            inReplyTo
            dateHuman
            sender
            text
            html
            signature
            isSignature
        }

        switch props.action
            when MessageActions.REPLY
                @setMessageAsReply options

            when MessageActions.REPLY_ALL
                @setMessageAsReplyAll options

            when MessageActions.FORWARD
                @setMessageAsForward options

            when null
                @setMessageAsDefault options

        message


    # Build message to display in composer in case of a reply to a message:
    # * set subject automatically (Re: previous subject)
    # * Set recipient based on sender
    # * add a style header for proper display
    # * Add quote of the previous message at the beginning of the message
    # * adds a signature at the message end.
    setMessageAsReply: (options) ->
        {
            message
            inReplyTo
            dateHuman
            sender
            text
            html
            signature
            isSignature
        } = options


        params = date: dateHuman, sender: sender
        separator = t 'compose reply separator', params
        message.to = _getReplyToAddress inReplyTo
        message.cc = []
        message.bcc = []
        message.subject = _getReplySubject inReplyTo
        message.text = separator + _generateReplyText(inReplyTo) + "\n"
        message.html = """
        #{COMPOSE_STYLE}
        <p><br></p>
        """

        if isSignature
            _addSignature message, signature

        message.html += """
            <p>#{separator}<span class="originalToggle"> … </span></p>
            <blockquote style="#{QUOTE_STYLE}">#{html}</blockquote>
            """

    # Build message to display in composer in case of a reply to all message:
    # * set subject automatically (Re: previous subject)
    # * Set recipients based on all people set in the conversation.
    # * add a style header for proper display
    # * Add quote of the previous message at the beginning of the message
    # * adds a signature at the message end.
    setMessageAsReplyAll: (options) ->
        {
            message
            inReplyTo
            dateHuman
            sender
            text
            html
            signature
            isSignature
        } = options

        params = date: dateHuman, sender: sender
        separator = t 'compose reply separator', params
        message.to = _getReplyToAddress inReplyTo
        # filter to don't have same address twice
        toAddresses = message.to?.map (dest) -> return dest.address

        message.cc = [].concat(
            inReplyTo?.get 'from'
            inReplyTo?.get 'to'
            inReplyTo?.get 'cc'
        ).filter (dest) ->
            return dest? and -1 is toAddresses.indexOf dest.address
        message.bcc = []

        message.subject = _getReplySubject inReplyTo
        message.text = separator + _generateReplyText(inReplyTo) + "\n"
        message.html = """
            #{COMPOSE_STYLE}
            <p><br></p>
        """

        if isSignature
            _addSignature message, signature

        message.html += """
            <p>#{separator}<span class="originalToggle"> … </span></p>
            <blockquote style="#{QUOTE_STYLE}">#{html}</blockquote>
            <p><br></p>
            """


    # Build message to display in composer in case of a message forwarding:
    # * set subject automatically (fwd: previous subject)
    # * add a style header for proper display
    # * Add forward information at the beginning of the message
    # We don't add signature here (see Thunderbird behavior)
    setMessageAsForward: (options) ->
        {
            message
            inReplyTo
            dateHuman
            sender
            text
            html
            signature
            isSignature
        } = options

        addresses = inReplyTo?.get('to')
        .map (address) -> address.address
        .join ', '

        senderInfos = _getReplyToAddress inReplyTo
        senderName = ""

        senderAddress =
        if senderInfos?.length
            senderName = senderInfos[0].name
            senderAddress = senderInfos[0].address

        if senderName?.length
            fromField = "#{senderName} &lt;#{senderAddress}&gt;"
        else
            fromField = senderAddress

        separator = """

----- #{t 'compose forward header'} ------
#{t 'compose forward subject'} #{inReplyTo.get 'subject'}
#{t 'compose forward date'} #{dateHuman}
#{t 'compose forward from'} #{fromField}
#{t 'compose forward to'} #{addresses}

"""
        textSeparator = separator.replace('&lt;', '<').replace('&gt;', '>')
        textSeparator = textSeparator.replace('<pre>', '').replace('</pre>', '')
        htmlSeparator = separator.replace /(\n)+/g, '<br>'

        @setMessageAsDefault options
        message.subject = """
            #{t 'compose forward prefix'}#{inReplyTo.get 'subject'}
            """
        message.text = textSeparator + text
        message.html = "#{COMPOSE_STYLE}"

        if isSignature
            _addSignature message, signature

        message.html += """

<p>#{htmlSeparator}</p><p><br></p>#{html}
"""
        message.attachments = inReplyTo.get 'attachments'

        return message



    # Clear all fields of the message object.
    # Add signature if given.
    setMessageAsDefault: (options) ->
        {
            message
            inReplyTo
            dateHuman
            sender
            text
            html
            signature
            isSignature
        } = options

        message.to = []
        message.cc = []
        message.bcc = []
        message.subject = ''
        message.text = ''
        message.html = "#{COMPOSE_STYLE}\n<p><br></p>"

        if isSignature
            _addSignature message, signature

        return message


    # To keep HTML markup light, create the contact tooltip dynamicaly
    # on mouse over
    # options:
    #  - container  : tooltip container
    #  - delay      : nb of miliseconds to wait before displaying tooltip
    #  - showOnClick: set to true to display tooltip when clicking on element
    tooltip: (node, address, onAdd, options) ->
        options ?= {}
        timeout = null
        doAdd = (e) ->
            e.preventDefault()
            e.stopPropagation()
            onAdd address
        addTooltip = (e) ->
            if node.dataset.tooltip
                return
            node.dataset.tooltip = true
            contact = ContactGetter.getByAddress address
            avatar  = contact?.get 'avatar'
            add   = ''
            image = ''
            if contact?
                if avatar?
                    image = "<img class='avatar' src=#{avatar}>"
                else
                    image = "<div class='no-avatar'>?</div>"
                image = """
                <div class="tooltip-avatar">
                  <a href="/#apps/contacts/contact/#{contact.get 'id'}" target="blank">
                    #{image}
                  </a>
                </div>
                """
            else
                if onAdd?
                    add = """
                    <p class="tooltip-toolbar">
                      <button class="btn btn-cozy btn-add" type="button">
                      #{t 'contact button label'}
                      </button>
                    </p>
                    """
            template = """
                <div class="tooltip" role="tooltip">
                    <div class="tooltip-arrow"></div>
                    <div class="tooltip-content">
                        #{image}
                        <div>
                        #{address.name}
                        #{if address.name then '<br>' else ''}
                        &lt;#{address.address}&gt;
                        </div>
                        #{add}
                    </div>
                </div>'
                """
            options =
                title: address.address
                template: template
                trigger: 'manual'
                placement: 'auto top'
                container: options.container or node.parentNode
            jQuery(node).tooltip(options).tooltip('show')
            tooltipNode = jQuery(node).data('bs.tooltip').tip()[0]
            if parseInt(tooltipNode.style.left, 10) < 0
                tooltipNode.style.left = 0
            rect = tooltipNode.getBoundingClientRect()
            mask = document.createElement 'div'
            mask.classList.add 'tooltip-mask'
            mask.style.top    = (rect.top - 8) + 'px'
            mask.style.left   = (rect.left - 8) + 'px'
            mask.style.height = (rect.height + 32) + 'px'
            mask.style.width  = (rect.width  + 16) + 'px'
            document.body.appendChild mask
            mask.addEventListener 'mouseout', (e) ->
                if not ( rect.left < e.pageX < rect.right) or
                   not ( rect.top  < e.pageY < rect.bottom)
                    mask.parentNode.removeChild mask
                    removeTooltip()
            if onAdd?
                addNode = tooltipNode.querySelector('.btn-add')
                if addNode?
                    addNode.addEventListener 'click', doAdd
        removeTooltip = ->
            addNode = node.querySelector('.btn-add')
            if addNode?
                addNode.removeEventListener 'click', doAdd
            delete node.dataset.tooltip
            jQuery(node).tooltip('destroy')

        node.addEventListener 'mouseover', ->
            timeout = setTimeout ->
                addTooltip()
            , options.delay or 1000
        node.addEventListener 'mouseout', ->
            clearTimeout timeout
        if options.showOnClick
            node.addEventListener 'click', (event) ->
                event.stopPropagation()
                addTooltip()


    formatContent: (message) ->
        displayHTML = SettingsStore.get 'messageDisplayHTML'

        # display full headers
        fullHeaders = []
        for key, value of message.get 'headers'
            value = value.join('\n ') if Array.isArray value
            fullHeaders.push "#{key}: #{value}"

        # Do not display content
        # if message isnt active
        text = message.get 'text'
        html = message.get 'html'

        # Some calendar invitation
        # may contain neither text nor HTML part
        if not text?.length and not html?.length
            text = if (message.get 'alternatives')?.length
                t 'calendar unknown format'

        # TODO: Do we want to convert text only messages to HTML ?
        # /!\ if displayHTML is set, this method should always return
        # a value fo html, otherwise the content of the email flashes
        if text?.length and not html?.length and displayHTML
            try
                html = markdown.toHTML text.replace(/(^>.*$)([^>]+)/gm, "$1\n$2")
                html = "<div class='textOnly'>#{html}</div>"
            catch e
                html = "<div class='textOnly'>#{text}</div>"

        # Convert text into markdown
        if html?.length and not text?.length and not displayHTML
            text = toMarkdown html

        if text?.length
            # Tranform URL into links
            urls = /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/gim

            rich = text.replace urls, '<a href="$1" target="_blank">$1</a>'

            # Tranform Separation chars into HTML
            rich = rich.replace /^>>>>>[^>]?.*$/gim, '<span class="quote5">$&</span><br />\r\n'
            rich = rich.replace /^>>>>[^>]?.*$/gim, '<span class="quote4">$&</span><br />\r\n'
            rich = rich.replace /^>>>[^>]?.*$/gim, '<span class="quote3">$&</span><br />\r\n'
            rich = rich.replace /^>>[^>]?.*$/gim, '<span class="quote2">$&</span><br />\r\n'
            rich = rich.replace /^>[^>]?.*$/gim, '<span class="quote1">$&</span><br />\r\n'

        attachments = message.get 'attachments'
        if html?.length
            displayImages = message?.get('_displayImages') or false
            props = {html, attachments, displayImages}
            {html, imagesWarning} = _cleanHTML props

        return {
            attachments     : attachments
            fullHeaders     : fullHeaders
            imagesWarning   : imagesWarning
            text            : text
            rich            : rich
            html            : html
        }



_cleanContent = (message) ->
    {html, text} = message

    text = toMarkdown html or ''
    text = _cleanReplyText text or ''

    html = _cleanHTML {html}
    # html = _wrapReplyHtml html

    return {html, text}


# set source of attached images
_cleanHTML = (props={}) ->
    {html, attachments, displayImages} = props
    imagesWarning = false
    displayImages ?= SettingsStore.get 'messageDisplayImages'

    # Add HTML to a document
    parser = new DOMParser()
    unless (doc = parser.parseFromString html, "text/html")
        doc = document.implementation.createHTMLDocument("")
        doc.documentElement.innerHTML = """<html><head>
               <link rel="stylesheet" href="./fonts/fonts.css" />
               <link rel="stylesheet" href="./mail_stylesheet.css" />
               <style>body { visibility: hidden; }</style>
           </head><body>#{html}</body></html>"""

    unless doc
        console.error "Unable to parse HTML content of message"
        html = null
    else
        unless displayImages
            imagesWarning = doc.querySelectorAll('IMG[src]').length isnt 0

        # Format links:
        # - open links into a new window
        # - convert relative URL to absolute
        for link in doc.querySelectorAll 'a[href]'
           link.target = '_blank'
           _toAbsolutePath link, 'href'

        for image in doc.querySelectorAll 'img[src]'
            # Do not display pictures
            # when user doesnt want to
            if imagesWarning
                image.parentNode.removeChild image


        html = doc.documentElement.innerHTML

    return {html, imagesWarning}


# Remove from given string:
# * html tags
# * extra spaces between reply markers and text
# * empty reply lines
_cleanReplyText = (html) ->

    # Convert HTML to markdown
    try
        result = html.replace /<(style>)[^\1]*\1/gim, ''
        result = toMarkdown result
    catch
        if html?
            result = html.replace /<(style>)[^\1]*\1/gim, ''
            result = html.replace /<[^>]*>/gi, ''

    # convert HTML entities
    tmp = document.createElement 'div'
    tmp.innerHTML = result
    result = tmp.textContent

    # Make citation more human readable.
    result = result.replace />[ \t]+/ig, '> '
    result = result.replace /(> \n)+/g, '> \n'
    result


# Add additional html tags to HTML replies:
# * add style block to change the blockquotes styles.
# * make "pre" without background
# * remove margins to "p"
_wrapReplyHtml = (html) ->
    parser = new DOMParser()
    doc = parser.parseFromString html, "text/html"
    content = doc.querySelectorAll '[class=wrappedContent]'
    if content.length
        html = content[0].innerHTML

    html = html?.replace /<p>/g, '<p style="margin: 0">'
    return """
        <style type="text/css">
        blockquote {
            margin: 0.8ex;
            padding-left: 1ex;
            border-left: 3px solid #34A6FF;
        }
        p {margin: 0;}
        pre {background: transparent; border: 0}
        </style>
        <span class="wrappedContent">#{html}</span>
        """


# Add signature at the end of the message
_addSignature = (message, signature) ->
    message.text += "\n\n-- \n#{signature}"
    signatureHtml = signature.replace /\n/g, '<br>'
    message.html += """
    <p><br></p><p id="signature">-- \n<br>#{signatureHtml}</p>
    <p><br></p>
        """


# Extract a reply address from a `message` object.
_getReplyToAddress = (message) ->
    reply = message?.get 'replyTo'
    from = message?.get 'from'
    if (reply? and reply.length isnt 0)
        return reply
    else
        return from

# Add a reply prefix to the current subject.
# Do not add it again if it's already there.
_getReplySubject = (message) ->
    subject =  message?.get('subject') or ''
    prefix = t 'compose reply prefix'
    if subject.indexOf(prefix) isnt 0
        subject = "#{prefix}#{subject}"
    subject


# Generate reply text by adding `>`
# before each line of the given text.
_generateReplyText = (message) ->
    text = message?.get('text') or ''
    result = _.map text.split('\n'), (line) -> "> #{line}"
    result.join "\n"


_toAbsolutePath = (elm, attribute, prefix='http://') ->
    RGXP_PROTOCOL = /:\/\//
    value = elm.getAttribute attribute
    if value?.length and not RGXP_PROTOCOL.test value
        elm.setAttribute attribute, prefix + value
