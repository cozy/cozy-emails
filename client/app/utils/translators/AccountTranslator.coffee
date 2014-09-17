module.exports =

    # Creates an immutable account from a raw account object
    toImmutable: (rawAccount) ->

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