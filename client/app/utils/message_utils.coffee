{ComposeActions} = require '../constants/app_constants'
ContactStore     = require '../stores/contact_store'

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

    getReplyToAddress: (message) ->
        reply = message.get 'replyTo'
        from = message.get 'from'
        if (reply? and reply.length isnt 0)
            return reply
        else
            return from

    makeReplyMessage: (inReplyTo, action, inHTML) ->
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
                    console.log "Error converting text message to Markdown: #{e}"
                    html = "<div class='text'>#{text}</div>" #markdown.toHTML text

            if html and not text and not inHTML
                text = toMarkdown html

            message.inReplyTo  = inReplyTo.get 'id'
            message.references = inReplyTo.get('references') or []
            message.references = message.references.concat message.inReplyTo

        switch action
            when ComposeActions.REPLY
                message.to = @getReplyToAddress inReplyTo
                message.cc = []
                message.bcc = []
                message.subject = "#{t 'compose reply prefix'}#{inReplyTo.get 'subject'}"
                message.text = t('compose reply separator', {date: dateHuman, sender: sender}) +
                    @generateReplyText(text) + "\n"
                message.html = """
                    <p><br /></p>
                    <p>#{t('compose reply separator', {date: dateHuman, sender: sender})}<span class="originalToggle"> … </span></p>
                    <blockquote>#{html}</blockquote>
                    <p><br /></p>
                    """
            when ComposeActions.REPLY_ALL
                message.to = @getReplyToAddress inReplyTo
                message.cc = [].concat inReplyTo.get('to'), inReplyTo.get('cc')
                message.bcc = []
                message.subject = "#{t 'compose reply prefix'}#{inReplyTo.get 'subject'}"
                message.text = t('compose reply separator', {date: dateHuman, sender: sender}) +
                    @generateReplyText(text) + "\n"
                message.html = """
                    <p><br /></p>
                    <p>#{t('compose reply separator', {date: dateHuman, sender: sender})}<span class="originalToggle"> … </span></p>
                    <blockquote>#{html}</blockquote>
                    <p><br /></p>
                    """
            when ComposeActions.FORWARD
                message.to = []
                message.cc = []
                message.bcc = []
                message.subject = "#{t 'compose forward prefix'}#{inReplyTo.get 'subject'}"
                message.text = t('compose forward separator', {date: dateHuman, sender: sender}) + text
                message.html = "<p>#{t('compose forward separator', {date: dateHuman, sender: sender})}</p>" + html

                # Add original message attachments
                message.attachments = inReplyTo.get 'attachments'

            when null
                message.to      = []
                message.cc      = []
                message.bcc     = []
                message.subject = ''
                message.text    = t 'compose default'

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
