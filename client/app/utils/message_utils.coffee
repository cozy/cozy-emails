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

    parseAddress: (text) ->
        text = text.trim()
        if match = text.match /"{0,1}(.*)"{0,1} <(.*)>/
            address =
                name: match[1]
                address: match[2]
        else
            address =
                address: text.replace(/^\s*/, '')

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

        if inReplyTo
            message.accountID = inReplyTo.get 'accountID'
            dateHuman = @formatDate inReplyTo.get 'createdAt'
            sender = @displayAddresses inReplyTo.get 'from'

            text = inReplyTo.get 'text'
            html = inReplyTo.get 'html'

            if text and not html and inHTML
                try
                    html = markdown.toHTML text
                catch e
                    console.log "Error converting message to Markdown: #{e}"
                    html = "<div class='text'>#{text}</div>"

            if html and not text and not inHTML
                text = toMarkdown html

            message.inReplyTo  = inReplyTo.get 'id'
            message.references = inReplyTo.get('references') or []
            message.references = message.references.concat message.inReplyTo

        switch action
            when ComposeActions.REPLY
                separator = t('compose reply separator',
                    {date: dateHuman, sender: sender})
                message.to = @getReplyToAddress inReplyTo
                message.cc = []
                message.bcc = []
                message.subject = """
                    #{t 'compose reply prefix'}#{inReplyTo.get 'subject'}
                    """
                message.text = separator + @generateReplyText(text) + "\n"
                message.html = """
                    <p><br /></p>
                    <p>#{separator}<span class="originalToggle"> … </span></p>
                    <blockquote>#{html}</blockquote>
                    <p><br /></p>
                    """
            when ComposeActions.REPLY_ALL
                separator = t('compose reply separator',
                    {date: dateHuman, sender: sender})
                message.to = @getReplyToAddress inReplyTo
                # filter to don't have same address twice
                toAddresses = message.to.map (dest) -> return dest.address
                message.cc = [].concat(inReplyTo.get('from'),
                    inReplyTo.get('to'),
                    inReplyTo.get('cc')).filter (dest) ->
                    return dest? and toAddresses.indexOf(dest.address) is -1
                message.bcc = []
                message.subject = """
                    #{t 'compose reply prefix'}#{inReplyTo.get 'subject'}
                    """
                message.text = separator + @generateReplyText(text) + "\n"
                message.html = """
                    <p><br /></p>
                    <p>#{separator}<span class="originalToggle"> … </span></p>
                    <blockquote>#{html}</blockquote>
                    <p><br /></p>
                    """
            when ComposeActions.FORWARD
                separator = t('compose forward separator',
                    {date: dateHuman, sender: sender})
                message.to = []
                message.cc = []
                message.bcc = []
                message.subject = """
                    #{t 'compose forward prefix'}#{inReplyTo.get 'subject'}
                    """
                message.text = separator + text
                message.html = "<p>#{separator}</p>" + html

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

    formatDate: (date, compact) ->
        if not date?
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
    # @params {Mixed}    ids          messageID or Message or array of messageIDs or Messages
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
