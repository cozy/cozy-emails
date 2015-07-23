{ComposeActions} = require '../constants/app_constants'
ContactStore     = require '../stores/contact_store'


QUOTE_STYLE = "margin-left: 0.8ex; padding-left: 1ex; border-left: 3px solid #34A6FF;"

# Style is required to clean pre and p styling in compose editor.
# It is removed by the visulasation iframe that's why we need to put
# style at the p level too.
COMPOSE_STYLE = """
<style>
pre {background: transparent; border: 0}
</style>
"""



module.exports = MessageUtils =


    # Build string showing address from an `adress` object. If a mail is given
    # in the `address` object, the string return this:
    #
    # Sender Name <email@sender.com>
    displayAddress: (address, full = false) ->
        if full
            if address.name? and address.name isnt ""
                return "\"#{address.name}\" <#{address.address}>"
            else
                return "#{address.address}"
        else
            if address.name? and address.name isnt ""
                return address.name
            else
                return address.address.split('@')[0]


    # Build a string from a list of `adress` objects. Addresses are
    # separated by a coma. An address is either the email adress either this:
    #
    # Sender Name <email@sender.com>
    displayAddresses: (addresses, full = false) ->
        if not addresses?
            return ""
        else
            res = []
            for item in addresses
                if not item?
                    break
                res.push(MessageUtils.displayAddress item, full)
            return res.join ", "


    # From a text, build an `address` object (name and address).
    # Add a isValid field if the given email is well formed.
    parseAddress: (text) ->
        text = text.trim()
        if match = text.match /"{0,1}(.*)"{0,1} <(.*)>/
            address =
                name: match[1]
                address: match[2]
        else
            address =
                address: text.replace(/^\s*/, '')

        # Test email validity
        emailRe = /^([A-Za-z0-9_\-\.])+\@([A-Za-z0-9_\-\.])+\.([A-Za-z]{2,4})$/
        address.isValid = address.address.match emailRe

        address


    # Extract a reply address from a `message` object.
    getReplyToAddress: (message) ->
        reply = message.get 'replyTo'
        from = message.get 'from'
        if (reply? and reply.length isnt 0)
            return reply
        else
            return from

    # Add signature at the end of the message
    addSignature: (message, signature) ->
        message.text += "\n\n-- \n#{signature}"
        signatureHtml = signature.replace /\n/g, '<br>'
        message.html += """
        <p><br></p><p id="signature">-- \n<br>#{signatureHtml}</p>
        <p><br></p>
            """

    # Build message to put in the email composer depending on the context
    # (reply, reply to all, forward or simple message).
    # It add appropriate headers to the message. It adds style tags when
    # required too.
    # It adds signature at the end of the zone where the user will type.
    makeReplyMessage: (myAddress, inReplyTo, action, inHTML, signature) ->
        message =
            composeInHTML: inHTML
            attachments: Immutable.Vector.empty()

        if inReplyTo
            message.accountID = inReplyTo.get 'accountID'
            message.conversationID = inReplyTo.get 'conversationID'
            dateHuman = @formatReplyDate inReplyTo.get 'createdAt'
            sender = @displayAddresses inReplyTo.get 'from'

            text = inReplyTo.get 'text'
            html = inReplyTo.get 'html'

            text = '' unless text? # Some message have no content, only attachements

            if text? and not html? and inHTML
                try
                    html = markdown.toHTML text
                catch e
                    console.error "Error converting message to Markdown: #{e}"
                    html = "<div class='text'>#{text}</div>"

            if html? and not text? and not inHTML
                text = toMarkdown html

            message.inReplyTo  = [inReplyTo.get 'id']
            message.references = inReplyTo.get('references') or []
            message.references = message.references.concat message.inReplyTo

        if signature? and signature.length > 0
            isSignature = true
        else
            isSignature = false

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

        switch action

            when ComposeActions.REPLY
                @setMessageAsReply options

            when ComposeActions.REPLY_ALL
                @setMessageAsReplyAll options

            when ComposeActions.FORWARD
                @setMessageAsForward options

            when null
                @setMessageAsDefault options

        # remove my address from dests
        notMe = (dest) -> return dest.address isnt myAddress
        message.to = message.to.filter notMe
        message.cc = message.cc.filter notMe
        return message


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
        message.to = @getReplyToAddress inReplyTo
        message.cc = []
        message.bcc = []
        message.subject = @getReplySubject inReplyTo
        message.text = separator + @generateReplyText(text) + "\n"
        message.html = """
        #{COMPOSE_STYLE}
        <p><br></p>
        """

        if isSignature
            @addSignature message, signature
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
        message.to = @getReplyToAddress inReplyTo
        # filter to don't have same address twice
        toAddresses = message.to.map (dest) -> return dest.address

        message.cc = [].concat(
            inReplyTo.get('from'),
            inReplyTo.get('to'),
            inReplyTo.get('cc')
        ).filter (dest) ->
            return dest? and toAddresses.indexOf(dest.address) is -1
        message.bcc = []

        message.subject = @getReplySubject inReplyTo
        message.text = separator + @generateReplyText(text) + "\n"
        message.html = """
            #{COMPOSE_STYLE}
            <p><br></p>
        """

        if isSignature
            @addSignature message, signature

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

        addresses = inReplyTo.get('to')
        .map (address) -> address.address
        .join ', '

        senderInfos = @getReplyToAddress inReplyTo
        senderName = ""

        senderAddress =
        if senderInfos.length > 0
            senderName = senderInfos[0].name
            senderAddress = senderInfos[0].address

        if senderName.length > 0
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
            @addSignature message, signature

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
            @addSignature message, signature

        return message


    # Generate reply text by adding `>` before each line of the given text.
    generateReplyText: (text) ->
        text = text.split '\n'
        res  = []
        text.forEach (line) ->
            res.push "> #{line}"
        return res.join "\n"


    # Guess simple attachment type from mime type.
    getAttachmentType: (type) ->
        return null unless type
        sub = type.split '/'

        switch sub[0]

            when 'audio', 'image', 'text', 'video'
                return sub[0]

            when "application"
                switch sub[1]

                    when "vnd.ms-excel",\
                         "vnd.oasis.opendocument.spreadsheet",\
                         "vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                        return "spreadsheet"

                    when "msword",\
                         "vnd.ms-word",\
                         "vnd.oasis.opendocument.text",\
                         "vnd.openxmlformats-officedocument.wordprocessingm" + \
                         "l.document"
                        return "word"

                    when "vns.ms-powerpoint",\
                         "vnd.oasis.opendocument.presentation",\
                         "vnd.openxmlformats-officedocument.presentationml." + \
                         "presentation"
                        return "presentation"

                    when "pdf" then return sub[1]

                    when "gzip", "zip" then return 'archive'


    # Format date to a conventional format for reply headers.
    formatReplyDate: (date) ->
        date = moment() unless date?
        date = moment date
        date.format 'lll'


    # Display date as a readable string.
    # Make it shorter if compact is set to true.
    formatDate: (date, compact) ->

        unless date?
            return null

        else
            today = moment()
            date  = moment date

            if date.isBefore today, 'year'
                formatter = 'DD/MM/YYYY'

            else if date.isBefore today, 'day'

                if compact? and compact
                    formatter = 'L'
                else
                    formatter = 'MMM DD'

            else
                formatter = 'HH:mm'

            return date.format formatter


    # Return avatar corresponding to sender by matching his email address with
    # addresses from existing contacts.
    getAvatar: (message) ->
        if message.get('from')[0]?
            return ContactStore.getAvatar message.get('from')[0].address
        else
            return null


    # Remove from given string:
    # * html tags
    # * extra spaces between reply markers and text
    # * empty reply lines
    cleanReplyText: (html) ->

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
    wrapReplyHtml: (html) ->
        html = html.replace /<p>/g, '<p style="margin: 0">'
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
            #{html}
            """

    # Add a reply prefix to the current subject. Do not add it again if it's
    # already there.
    getReplySubject: (inReplyTo) ->
        subject =  inReplyTo.get('subject') or ''
        replyPrefix = t 'compose reply prefix'
        if subject.indexOf(replyPrefix) isnt 0
            subject = "#{replyPrefix}#{subject}"
        subject

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
            contact = ContactStore.getByAddress address.address
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
