_ = require 'lodash'
sanitizer   = require 'sanitizer'
REGEXP =
    hasReOrFwD: /^(Re|Fwd)/i
    subject: /(?:(?:Re|Fwd)(?:\[[\d+]\])?\s?:\s?)*(.*)/i
    messageId: /<([^<>]+)>/

IGNORE_ATTRIBUTES = ['\\HasNoChildren', '\\HasChildren']


module.exports =
    isReplyOrForward: (subject) ->
        match = subject.match REGEXP.hasReOrFwD
        return if match then true else false

    normalizeSubject: (subject) ->
        match = subject.match REGEXP.subject
        return if match then match[1] else false

    normalizeMessageID: (messageId) ->
        match = messageId.match REGEXP.messageId
        return if match then match[1] else null

    flattenMailboxTree: (tree) ->
        boxes = []

        # first level is only INBOX, with no siblings
        if Object.keys(tree).length is 1 and root = tree['INBOX']
            delimiter = root.delimiter
            path = 'INBOX' + delimiter
            flattenMailboxTreeLevel boxes, root.children, path, [], delimiter
        else
            flattenMailboxTreeLevel boxes, tree, '', [], '/'
        return boxes

    sanitizeHTML: (html) ->
        sanitizer.sanitize html, (url) ->
            url = url.toString()
            if 0 is url.indexOf 'cid://'
                cid = url.substring 6
                attachment = message.attachments.filter (att) ->
                    att.contentId is cid

                if name = attachment?[0].name
                    return "/message/#{message.id}/attachments/#{name}"
                else
                    return null

            else return url.toString()


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
