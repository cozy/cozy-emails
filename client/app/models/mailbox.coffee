Immutable = require 'immutable'
{MailboxFlags} = require '../constants/app_constants'
DEFAULTORDER = 100
FLAGSORDER = Object.keys(MailboxFlags).map (key) -> MailboxFlags[key]


Mailbox = Immutable.Record
    # server fields
    label: undefined
    lastSync: undefined
    tree: undefined
    attribs: undefined
    # accountID: undefined
    # lastTotal: undefined
    # path: undefined
    # delimiter: undefined
    # lastHighestModSeq: undefined
    # uidvalidity: undefined

    id: undefined
    # _id: undefined

    # client fields
    nbTotal: undefined
    nbUnread: undefined
    nbFlagged: undefined
    nbSent: undefined
    nbRecent: undefined
    order: undefined

# fuunction used to sort a list of mailbox
Mailbox.sortFunction = (mb1, mb2) ->
    if mb1.order > mb2.order
        return 1
    else if mb1.order < mb2.order
        return -1

    # Ordering by path
    if mb1.tree? and mb2.tree?
        path1 = mb1.tree.join('/').toLowerCase()
        path2 = mb2.tree.join('/').toLowerCase()
        return path1.localeCompare path2

Mailbox::hasAttrib = (attrib) ->
    attrib in (@get('attribs') or [])

Mailbox::removeAttrib = (attrib) ->
    attribs = (@get('attribs') or [])
    attribs = attribs.filter (x) -> x isnt attrib
    if attribs.length
        @set('attribs', attribs)
    else
        @set('attribs', undefined)

Mailbox::childOf = (otherbox) ->
    (@get('tree') or []).indexOf(otherbox.get('label')) isnt -1


Mailbox::isInbox = ->
    @get('attribs')?.length is 1 and
    MailboxFlags.INBOX is @get('attribs')[0]

Mailbox::hasEmpty = (field) ->
    value = @get(field)
    return true unless value
    clean = value.filter (part) -> Boolean(part)
    return true if clean.length is 0

# give
Mailbox.getFlagOrder = (attrib) ->
    idx = FLAGSORDER.indexOf(attrib)
    idx = DEFAULTORDER if idx = -1
    return idx

Mailbox::withComputedOrder = ->
    attribs = @get('attribs')
    # @TODO rewrite this in a readable manner
    if attribs?.length
        value = attribs.reduce (result, attrib) ->
            index = Mailbox.getFlagOrder attrib
            result.push index if -1 < index
            result
        , []

        index = value.shift()
        if index?
            decimal = value.join ''
            index = "#{index}.#{decimal}" if value.length
            return @set('order', index * 1)

    return @set('order', DEFAULTORDER)

Mailbox.from = (rawMailbox) ->

    # Reset empty properties
    mailbox = new Mailbox(rawMailbox)

    # @TODO: is this necessary ? It seems cleaner to always have an array
    mailbox = mailbox.delete 'tree'    if mailbox.hasEmpty('tree')
    mailbox = mailbox.delete 'attribs' if mailbox.hasEmpty('attribs')

    # Get order based on attribs value
    mailbox = mailbox.withComputedOrder 100

    return mailbox

module.exports = Mailbox
