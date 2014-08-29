module.exports =

    # Creates an immutable account from a raw account object
    toImmutable: (rawAccount) ->

        # Recursively creates Immutable OrderedMap of mailboxes
        _createImmutableMailboxes = (children) ->
            Immutable.Sequence children
                .mapKeys (_, mailbox) -> mailbox.id
                .map (mailbox) ->
                    mailbox.children = _createImmutableMailboxes mailbox.children
                    return Immutable.Map mailbox
                .toOrderedMap()

        rawAccount.mailboxes = _createImmutableMailboxes rawAccount.mailboxes
        return Immutable.Map rawAccount


    toRawObject: toRawObject = (account) ->

        _createRawObjectMailboxes = (children) ->
            children?.map (child) ->
                return child.set 'children', _createRawObjectMailboxes child.get 'children'
            .toVector()

        account = account.set 'mailboxes', _createRawObjectMailboxes account.get 'mailboxes'

        return account.toJS()