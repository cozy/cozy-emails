{ComposeActions} = require '../constants/app_constants'
ContactStore     = require '../stores/contact_store'
MessageStore     = require '../stores/message_store'
ConversationActionCreator = require '../actions/conversation_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'
LayoutActionCreator       = require '../actions/layout_action_creator'

module.exports = MessageUtils =


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


    displayAddresses: (addresses, full = false) ->
        if not addresses?
            return ""

        res = []
        for item in addresses
            if not item?
                break
            res.push(MessageUtils.displayAddress item, full)
        return res.join ", "


    # From a text, build an address object (name and address).
    # Add a isValid field to
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


    getReplyToAddress: (message) ->
        reply = message.get 'replyTo'
        from = message.get 'from'
        if (reply? and reply.length isnt 0)
            return reply
        else
            return from


    makeReplyMessage: (myAddress, inReplyTo, action, inHTML) ->
        message =
            composeInHTML: inHTML
            attachments: Immutable.Vector.empty()
        quoteStyle = "margin-left: 0.8ex; padding-left: 1ex;"
        quoteStyle += " border-left: 3px solid #34A6FF;"

        if inReplyTo
            message.accountID      = inReplyTo.get 'accountID'
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
                    console.log "Error converting message to Markdown: #{e}"
                    html = "<div class='text'>#{text}</div>"

            if html? and not text? and not inHTML
                text = toMarkdown html

            message.inReplyTo  = [inReplyTo.get 'id']
            message.references = inReplyTo.get('references') or []
            message.references = message.references.concat message.inReplyTo

        switch action

            when ComposeActions.REPLY
                params = date: dateHuman, sender: sender
                separator = t 'compose reply separator', params
                message.to = @getReplyToAddress inReplyTo
                message.cc = []
                message.bcc = []
                message.subject = @getReplySubject inReplyTo
                message.text = separator + @generateReplyText(text) + "\n"
                message.html = """
                    <p>#{separator}<span class="originalToggle"> … </span></p>
                    <blockquote style="#{quoteStyle}">#{html}</blockquote>
                    <p><br /></p>
                    """

            when ComposeActions.REPLY_ALL
                params = date: dateHuman, sender: sender
                separator = t 'compose reply separator', params
                message.to = @getReplyToAddress inReplyTo

                # filter to don't have same address twice
                toAddresses = message.to.map (dest) -> return dest.address
                message.cc = [].concat(inReplyTo.get('from'),
                    inReplyTo.get('to'),
                    inReplyTo.get('cc')).filter (dest) ->
                    return dest? and toAddresses.indexOf(dest.address) is -1
                message.bcc = []
                message.subject = @getReplySubject inReplyTo
                message.text = separator + @generateReplyText(text) + "\n"
                message.html = """
                    <p>#{separator}<span class="originalToggle"> … </span></p>
                    <blockquote style="#{quoteStyle}">#{html}</blockquote>
                    <p><br /></p>
                    """

            when ComposeActions.FORWARD
                addresses = inReplyTo.get('to')
                .map (address) -> address.address
                .join ', '

                senderInfos = @getReplyToAddress inReplyTo
                senderName = ""
                senderAddress = ""
                if senderInfos.length > 0
                    senderName = senderInfos[0].name
                    senderAddress = senderInfos[0].address

                senderString = senderAddress
                if senderName.length > 0
                    fromField = "#{senderName} &lt;#{senderAddress}&gt;"

                separator = """

----- #{t 'compose forward header'} ------
#{t 'compose forward subject'} #{inReplyTo.get 'subject'}
#{t 'compose forward date'} #{dateHuman}
#{t 'compose forward from'} #{fromField}
#{t 'compose forward to'} #{addresses}

"""
                message.to = []
                message.cc = []
                message.bcc = []
                message.subject = """
                    #{t 'compose forward prefix'}#{inReplyTo.get 'subject'}
                    """
                message.text = separator + text
                htmlSeparator = separator.replace /(\n)+/g, '<br />'
                html = "<p>#{htmlSeparator}</p><p><br /></p>#{html}"
                message.html = html

                # Add original message attachments
                message.attachments = inReplyTo.get 'attachments'

            when null
                message.to      = []
                message.cc      = []
                message.bcc     = []
                message.subject = ''
                message.text    = ''
                message.html    = ''

        # remove my address from dests
        notMe = (dest) -> return dest.address isnt myAddress
        message.to = message.to.filter notMe
        message.cc = message.cc.filter notMe
        return message

    generateReplyText: (text) ->
        text = text.split '\n'
        res  = []
        text.forEach (line) ->
            res.push "> #{line}"
        return res.join "\n"

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


    formatReplyDate: (date) ->
        date = moment() unless date?
        date = moment date
        date.format 'lll'


    formatDate: (date, compact) ->
        unless date?
            return
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

    getAvatar: (message) ->
        if message.get('from')[0]?
            return ContactStore.getAvatar message.get('from')[0].address
        else
            return null

    # Delete message(s) or conversations
    #
    # @params {Mixed}    ids          messageID or Message or array of
    #                                 messageIDs or Messages
    # @params {Boolean}  conversation true to delete whole conversation
    # @params {Function} cb           callback
    delete: (ids, conversation, cb) ->
        @action 'delete', ids, conversation, null, cb

    move: (ids, conversation, from, to, cb) ->
        options =
            from: from
            to: to
        @action 'move', ids, conversation, options, cb

    action: (action, ids, conversation, options, cb) ->

        alertError   = LayoutActionCreator.alertError
        if Array.isArray ids
            mass = ids.length
            selected = ids
        else
            mass = 1
            selected = [ids]

        # If we deleted only one message, we'll navigate to the next one,
        # otherwise close preview panel and select first message
        if selected.length > 1
            window.cozyMails.messageClose()
        else
            next = MessageStore.getNextMessage conversation

        # Called once every message has been deleted
        onDone = _.after selected.length, ->
            if typeof cb is 'function'
                cb()

        # Handle one message
        handleMessage = (messageID) ->
            switch action
                when 'move'
                    MessageActionCreator.move messageID, options.from, options.to, (error) ->
                        if error?
                            alertError "#{t("message action move ko")} #{error}"
                        onDone()
                when 'delete'
                    MessageActionCreator.delete messageID, (error) ->
                        if error?
                            alertError "#{t("message action delete ko")} : #{error}"
                        onDone()

        # Handle one conversation
        handleConversation = (message) ->
            messageID = message.get 'id'
            # sometime, draft messages don't have a conversationID
            conversationID = message.get 'conversationID'
            if conversationID?
                switch action
                    when 'move'
                        ConversationActionCreator.move message, options.from, options.to, (error) ->
                            if error?
                                alertError "#{t("message action move ko", subject: message.get('subject'))} #{error}"
                            onDone()
                    when 'delete'
                        ConversationActionCreator.delete conversationID, (error) ->
                            if error?
                                alertError "#{t("conversation delete ko", subject: message.get('subject'))} : #{error}"
                            onDone()
            else
                handleMessage(messageID)

        selected.forEach (messageID) ->
            if conversation
                if typeof messageID is 'string'
                    message = MessageStore.getByID messageID
                else
                    message   = messageID
                handleConversation message
            else
                if typeof messageID isnt 'string'
                    messageID = messageID.get 'id'
                handleMessage messageID
        if next?
            MessageActionCreator.setCurrent next.get('id'), true
            # open next message if the deleted one was open
            window.cozyMails.messageDisplay next, false


    # Remove from given string:
    # * html tags
    # * extra spaces between reply markers and text
    # * empty reply lines
    cleanReplyText: (html) ->

        # Convert HTML to markdown
        try
            result = toMarkdown html
        catch
            result = html.replace /<[^>]*>/gi, '' if html?

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
    wrapReplyHtml: (html) ->
        return """
            <style type="text/css">
            blockquote {
                margin: 0.8ex;
                padding-left: 1ex;
                border-left: 3px solid #34A6FF;
            }
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
