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
        return if reply?.length isnt 0 then reply else from



    makeReplyMessage: (inReplyTo, action, inHTML) ->
        message =
            composeInHTML: inHTML

        if inReplyTo
            message.accountID = inReplyTo.get 'accountID'
            dateHuman = @formatDate inReplyTo.get 'createdAt'
            sender = @displayAddresses inReplyTo.get 'from'

            text = inReplyTo.get 'text'
            html = inReplyTo.get 'html'

            if text and not html and inHTML
                html = markdown.toHTML text

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
                message.body = t('compose reply separator', {date: dateHuman, sender: sender}) +
                    @generateReplyText(text) + "\n"
                message.html = """
                    <p><br /></p>
                    <p>#{t('compose reply separator', {date: dateHuman, sender: sender})}</p>
                    <blockquote>#{html}</blockquote>
                    """
            when ComposeActions.REPLY_ALL
                message.to = @getReplyToAddress inReplyTo
                message.cc = [].concat inReplyTo.get('to'), inReplyTo.get('cc')
                message.bcc = []
                message.subject = "#{t 'compose reply prefix'}#{inReplyTo.get 'subject'}"
                message.body = t('compose reply separator', {date: dateHuman, sender: sender}) +
                    @generateReplyText(text) + "\n"
                message.html = """
                    <p><br /></p>
                    <p>#{t('compose reply separator', {date: dateHuman, sender: sender})}</p>
                    <blockquote>#{html}</blockquote>
                    """
            when ComposeActions.FORWARD
                message.to = []
                message.cc = []
                message.bcc = []
                message.subject = "#{t 'compose forward prefix'}#{inReplyTo.get 'subject'}"
                message.body = t('compose forward separator', {date: dateHuman, sender: sender}) + text
                message.html = "<p>#{t('compose forward separator', {date: dateHuman, sender: sender})}</p>" + html

                # Add original message attachments
                attachments = inReplyTo.get 'attachments' or []
                message.attachments = attachments.map @convertAttachments

            when null
                message.to      = []
                message.cc      = []
                message.bcc     = []
                message.subject = ''
                message.body    = t 'compose default'

        return message

    generateReplyText: (text) ->
        text = text.split '\n'
        res  = []
        text.forEach (line) ->
            res.push "> #{line}"
        return res.join "\n"

    getAttachmentType: (type) ->
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

    # convert attachment to the format needed by the file picker
    convertAttachments: (file) ->
        name = file.generatedFileName
        return {
            name:               name
            size:               file.length
            type:               file.contentType
            originalName:       file.fileName
            contentDisposition: file.contentDisposition
            contentId:          file.contentId
            transferEncoding:   file.transferEncoding
            url: "/message/#{file.messageId}/attachments/#{name}"
        }

    formatDate: (date) ->
        if not date?
            return
        today = moment()
        date  = moment date
        if date.isBefore today, 'year'
            formatter = 'DD/MM/YYYY'
        else if date.isBefore today, 'day'
            formatter = 'DD MMMM'
        else
            formatter = 'hh:mm'
        return date.format formatter

    getAvatar: (message) ->
        return ContactStore.getAvatar message.get('from')[0].address
