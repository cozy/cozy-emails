{MailboxFlags} = require '../../constants/app_constants'

module.exports = AccountTranslator =

    mailboxToImmutable: (raw) ->

        raw.depth = raw.tree.length - 1

        box = Immutable.Map raw

    # Creates an immutable account from a raw account object
    toImmutable: (raw) ->

        # Used to sort mailboxes
        last = {}
        weight1 = 900
        weight2 = 400
        # Try to detect special mailboxes, first with flags, then by name
        # Already done on server, except for TEST accounts
        raw.mailboxes ?= []
        if not raw.draftMailbox? or
           not raw.sentMailbox? or
           not raw.trashMailbox?
            raw.mailboxes.forEach (box) ->
                # If needed, use mailboxes attribs to set draft, sent and trash
                if not raw.draftMailbox? and MailboxFlags.DRAFT in box.attribs
                    raw.draftMailbox = box.id
                if not raw.sentMailbox? and MailboxFlags.SENT in box.attribs
                    raw.sentMailbox = box.id
                if not raw.trashMailbox? and MailboxFlags.TRASH in box.attribs
                    raw.trashMailbox = box.id
        if not raw.draftMailbox? or
           not raw.sentMailbox? or
           not raw.trashMailbox?
            raw.mailboxes.forEach (box) ->
                if not raw.draftMailbox? and /draft/i.test box.label
                    raw.draftMailbox = box.id
                if not raw.sentMailbox? and /sent/i.test box.label
                    raw.sentMailbox = box.id
                if not raw.trashMailbox? and /trash/i.test box.label
                    raw.trashMailbox = box.id

        # Creates Immutable OrderedMap of mailboxes
        mailboxes = Immutable.Sequence raw.mailboxes
            .mapKeys (_, box) -> box.id
            .map (box) ->

                box.depth = box.tree.length - 1

                # fake weight for sort
                if box.depth is 0
                    label = box.label.toLowerCase()
                    if label is 'inbox'
                        box.weight = 1000
                    else if (box.attribs.length > 0 or
                            /draft/.test(label) or
                            /sent/.test(label) or
                            /trash/.test(label))
                        box.weight = weight1
                        weight1 -= 5
                    else
                        box.weight = weight2
                        weight2 -= 5
                    last[box.depth] = box.weight
                else
                    box.weight = last[box.depth - 1] - 0.1

                return AccountTranslator.mailboxToImmutable box

            .toOrderedMap()


        raw.mailboxes = mailboxes
        return Immutable.Map raw
