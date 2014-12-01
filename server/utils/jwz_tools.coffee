_ = require 'lodash'
sanitizeHtml = require 'sanitize-html'

REGEXP =
    hasReOrFwD: /^(Re|Fwd)/i
    subject: /(?:(?:Re|Fwd)(?:\[[\d+]\])?\s?:\s?)*(.*)/i
    messageID: /<([^<>]+)>/

IGNORE_ATTRIBUTES = ['\\HasNoChildren', '\\HasChildren']


module.exports =
    isReplyOrForward: (subject) ->
        match = subject.match REGEXP.hasReOrFwD
        return if match then true else false

    normalizeSubject: (subject) ->
        match = subject.match REGEXP.subject
        return if match then match[1] else false

    normalizeMessageID: (messageID) ->
        match = messageID.match REGEXP.messageID
        return if match then match[1] else null

    flattenMailboxTree: (tree) ->
        boxes = []

        # first level is only INBOX, with no siblings
        if Object.keys(tree).length is 1 and root = tree['INBOX']
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
        allowedTags = sanitizeHtml.defaults.allowedTags.concat [
            'img'
            'head'
            'meta'
        ]
        allowedAttributes = sanitizeHtml.defaults.allowedAttributes
        allowedTags.forEach (tag) ->
            if allowedAttributes[tag]?
                allowedAttributes[tag] = allowedAttributes[tag].concat ['style', 'class', 'background']
            else
                allowedAttributes[tag] = ['style', 'class', 'background']
        html = sanitizeHtml html,
            allowedTags: allowedTags
            allowedAttributes: allowedAttributes
            allowedClasses: false
            allowedSchemes: sanitizeHtml.defaults.allowedSchemes.concat ['cid']
            transformTags:
                'img': (tag, attribs) ->
                    if attribs.src? and 0 is attribs.src.indexOf 'cid:'
                        cid = attribs.src.substring 4
                        attachment = attachments.filter (att) ->
                            att.contentId is cid
                        name = attachment[0]?.fileName
                        if name?
                            attribs.src = "/message/#{messageId}/attachments/#{name}"
                    return {tagName: 'img', attribs: attribs}
        html


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
