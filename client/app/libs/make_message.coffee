# THIS FILE ISNT USED ANYWHERE

_           = require 'underscore'
moment      = require 'moment'
Immutable = require 'immutable'
{MessageActions} = require '../../constants/app_constants'
ContactFormat     = require '../../libs/format_adress'
QUOTE_STYLE = "margin-left: 0.8ex; padding-left: 1ex; "+
              "border-left: 3px solid #34A6FF;"
toMarkdown  = require 'to-markdown'
{cleanHTML} = require './format_message'

# Style is required to clean pre and p styling in compose editor.
# It is removed by the visulasation iframe that's why we need to put
# style at the p level too.
COMPOSE_STYLE = """
<style>
pre {background: transparent; border: 0}
</style>
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



# Build message to put in the email composer depending on the context
# (reply, reply to all, forward or simple message).
# It add appropriate headers to the message. It adds style tags when
# required too.
# It adds signature at the end of the zone where the user will type.
exports.createBasicMessage = (props) ->
    props = _.clone props

    account =
        id: props.account?.get 'id'
        name: props.account?.get 'name'
        address: props.account?.get 'login'
        signature: props.account?.get 'signature'

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
    sender = ContactFormat.displayAddresses message.from
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
exports.setMessageAsReply = (options) ->
    {
        message
        inReplyTo
        dateHuman
        sender
        # text
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
exports.setMessageAsReplyAll = (options) ->
    {
        message
        inReplyTo
        dateHuman
        sender
        # text
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
exports.setMessageAsForward = (options) ->
    {
        message
        inReplyTo
        dateHuman
        # sender
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
exports.setMessageAsDefault = (options) ->
    {
        message
        # inReplyTo
        # dateHuman
        # sender
        # text
        # html
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

_cleanContent = (message) ->
    {html, text} = message

    text = toMarkdown html or ''
    text = _cleanReplyText text or ''

    html = cleanHTML {html}
    # html = _wrapReplyHtml html

    return {html, text}
