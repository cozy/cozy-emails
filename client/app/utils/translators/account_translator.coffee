{MailboxFlags} = require '../../constants/app_constants'

module.exports =

    # Creates an immutable account from a raw account object
    toImmutable: (rawAccount) ->

        # If needed, use mailboxes attribs to set draft, sent and trash
        if not rawAccount.draftMailbox? or
        not rawAccount.sentMailbox? or
        not rawAccount.trashMailbox?
            mailboxes = {}
            checkAttribs = (box) ->
                if MailboxFlags.DRAFT in box.attribs
                    mailboxes.draft = box.id
                if MailboxFlags.SENT in box.attribs
                    mailboxes.sent = box.id
                if MailboxFlags.TRASH in box.attribs
                    mailboxes.trash = box.id
                box.children.forEach checkAttribs
            rawAccount.mailboxes.forEach checkAttribs

        if not rawAccount.draftMailbox? and mailboxes.draft?
            rawAccount.draftMailbox = mailboxes.draft
        if not rawAccount.sentMailbox? and mailboxes.sent?
            rawAccount.sentMailbox = mailboxes.sent
        if not rawAccount.trashMailbox? and mailboxes.trash?
            rawAccount.trashMailbox = mailboxes.trash

        # Recursively creates Immutable OrderedMap of mailboxes
        _createImmutableMailboxes = (children) ->
            Immutable.Sequence children
                .mapKeys (_, mailbox) -> mailbox.id
                .map (mailbox) ->
                    children = mailbox.children
                    mailbox.children = _createImmutableMailboxes children
                    return Immutable.Map mailbox
                .toOrderedMap()

        rawAccount.mailboxes = _createImmutableMailboxes rawAccount.mailboxes
        return Immutable.Map rawAccount


    toRawObject: toRawObject = (account) ->

        _createRawObjectMailboxes = (children) ->
            children?.map (child) ->
                children = child.get 'children'
                return child.set 'children', _createRawObjectMailboxes children
            .toVector()

        mailboxes = account.get 'mailboxes'
        account = account.set 'mailboxes', _createRawObjectMailboxes mailboxes

        return account.toJS()
