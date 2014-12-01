{MailboxFlags} = require '../../constants/app_constants'

module.exports = AccountTranslator =

    mailboxToImmutable: (raw) ->
        raw.depth = raw.tree.length - 1
        box = Immutable.Map raw

    # Creates an immutable account from a raw account object
    toImmutable: (raw) ->

        # Creates Immutable OrderedMap of mailboxes
        mailboxes = Immutable.Sequence raw.mailboxes
            .mapKeys (_, box) -> box.id
            .map (box) ->
                # If needed, use mailboxes attribs to set draft, sent and trash
                # @TODO, the server does it, remove this ?
                if not raw.draftMailbox? and MailboxFlags.DRAFT in box.attribs
                    raw.draftMailbox = mailboxes.draft

                if not raw.sentMailbox? and MailboxFlags.SENT in box.attribs
                    raw.sentMailbox = mailboxes.sent

                if not raw.trashMailbox? and MailboxFlags.TRASH in box.attribs
                    raw.trashMailbox = mailboxes.trash

                return AccountTranslator.mailboxToImmutable box

            .toOrderedMap()


        raw.mailboxes = mailboxes
        return Immutable.Map raw
