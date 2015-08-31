_ = require 'lodash'
sanitizeHtml = require 'sanitize-html'

REGEXP =
    hasReOrFwD: /^(Re|Fwd)/i
    subject: /(?:(?:Re|Fwd)(?:\[[\d+]\])?\s?:\s?)*(.*)/i
    messageID: /<([^<>]+)>/

IGNORE_ATTRIBUTES = ['\\HasNoChildren', '\\HasChildren']

allowedTags = sanitizeHtml.defaults.allowedTags.concat [
    'img'
    'head'
    'meta'
    'title'
    'link'
    'h1'
    'h2'
    'h3'
    'h4'
]
safeAttributes = [
    # general
    'style', 'class', 'background', 'bgcolor'
    # tables
    'colspan', 'rowspan', 'height', 'width', 'align', 'font-size',
    'cellpadding', 'cellspacing', 'border', 'valign'
    # body
   'leftmargin', 'marginwidth', 'topmargin', 'marginheight', 'offset',
    #microdata
    'itemscope', 'itemtype', 'itemprop', 'content'
]
allowedAttributes = sanitizeHtml.defaults.allowedAttributes
allowedTags.forEach (tag) ->
    exAllowed = allowedAttributes[tag] or []
    allowedAttributes[tag] = exAllowed.concat safeAttributes

allowedAttributes.link.push 'href'
allowedSchemes = sanitizeHtml.defaults.allowedSchemes
    .concat ['cid', 'data']

module.exports =
    isReplyOrForward: (subject) ->
        match = subject.match REGEXP.hasReOrFwD
        return if match then true else false

    normalizeSubject: (subject) ->
        match = subject.match REGEXP.subject
        return if match then match[1] else false

    normalizeMessageID: (messageID) ->
        match = messageID.match REGEXP.messageID
        return if match then match[1] else messageID

    flattenMailboxTree: (tree) ->
        boxes = []

        # first level is only INBOX, with no siblings
        if Object.keys(tree).length is 1 and tree['INBOX']
            root = tree['INBOX']
            delimiter = root.delimiter
            path = 'INBOX' + delimiter

            boxes.push
                label: 'INBOX'
                delimiter: delimiter
                path: 'INBOX'
                tree: ['INBOX']
                attribs: _.difference root.attribs, IGNORE_ATTRIBUTES

            flattenMailboxTreeLevel boxes, root.children, path, [], delimiter
        else
            flattenMailboxTreeLevel boxes, tree, '', [], '/'
        return boxes

    sanitizeHTML: (html, messageId, attachments) ->
        return sanitizeHtml html,
            allowedTags: allowedTags
            allowedAttributes: allowedAttributes
            allowedClasses: false
            allowedSchemes: allowedSchemes
            transformTags:
                'img': (tag, attribs) ->
                    if attribs.src? and 0 is attribs.src.indexOf 'cid:'
                        cid = attribs.src.substring 4
                        attachment = attachments.filter (att) ->
                            att.contentId is cid
                        if attachment[0]?.fileName
                            name = attachment[0]?.fileName
                            src = "message/#{messageId}/attachments/#{name}"
                            attribs.src = src
                        else
                            attribs.src = ""
                    # only allows inline images whose mimetype is image/*
                    if attribs.src? and 0 is attribs.src.indexOf 'data:'
                        mime = /data:([^\/]*)\/([^;]*);/.exec attribs.src
                        if not mime? or mime[1] isnt 'image'
                            attribs.src = ""
                    return {tagName: 'img', attribs: attribs}

# recursively browse the imap box tree building pathStr and pathArr
flattenMailboxTreeLevel= (boxes, children, pathStr, pathArr, parentDelimiter) ->

    for name, child of children

        delimiter = child.delimiter or parentDelimiter

        subPathStr = pathStr + name + delimiter
        subPathArr = pathArr.concat name

        flattenMailboxTreeLevel boxes, child.children, subPathStr,
                subPathArr, delimiter

        boxes.push
            label: name
            delimiter: delimiter
            path: pathStr + name
            tree: subPathArr
            attribs: _.difference child.attribs, IGNORE_ATTRIBUTES
