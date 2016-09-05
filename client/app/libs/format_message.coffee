SettingsStore = require('../getters/settings')
reduxStore = require('../redux_store')
{markdown}  = require 'markdown'
toMarkdown  = require 'to-markdown'

t = window.t


# set source of attached images
exports.cleanHTML = (props={}) ->
    {html, displayImages} = props
    imagesWarning = false
    state = reduxStore.getState()
    displayImages ?= SettingsStore.get state, 'messageDisplayImages'

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



_toAbsolutePath = (elm, attribute, prefix='http://') ->
    RGXP_PROTOCOL = /:\/\//
    value = elm.getAttribute attribute
    if value?.length and not RGXP_PROTOCOL.test value
        elm.setAttribute attribute, prefix + value

# coffeelint: disable=cyclomatic_complexity
exports.formatContent = (message) ->
    displayHTML = SettingsStore.get reduxStore.getState(), 'messageDisplayHTML'

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
        catch error
            html = "<div class='textOnly'>#{text}</div>"

    # Convert text into markdown
    if html?.length and not text?.length and not displayHTML
        text = toMarkdown html

    if text?.length
        # Tranform URL into links
        urls = ///
            (
                (
                    ([A-Za-z]{3,9}:(?:\/\/)?)
                    (?:[-;:&=\+\$,\w]+@)?
                    [A-Za-z0-9.-]+
                    |
                    (?:www.|[-;:&=\+\$,\w]+@)
                    [A-Za-z0-9.-]+
                )
                (
                    (?:\/[\+~%\/.\w-_]*)?
                    \??
                    (?:[-\+=&;%@.\w_]*)
                    #?(?:[\w]*)
                )?
            )
        ///gim

        rich = text.replace urls, '<a href="$1" target="_blank">$1</a>'

        # Tranform Separation chars into HTML
        for n in [5..1]
            rex = new RegExp "^#{Array(n+1).join('>')}[^>]?.*$", 'gim'
            rich = rich.replace rex, "<span class='quote#{n}'>$&</span><br>\r\n"


    attachments = message.get 'attachments'
    if html?.length
        displayImages = message?.get('_displayImages') or false
        props = {html, attachments, displayImages}
        {html, imagesWarning} = exports.cleanHTML props

    return {
        attachments     : attachments
        fullHeaders     : fullHeaders
        imagesWarning   : imagesWarning
        text            : text
        rich            : rich
        html            : html
    }
