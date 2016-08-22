{MailboxFlags} = require '../constants/app_constants'

DEFAULTORDER = 100

module.exports =

    getAll: (state) -> @getAllAccounts(state)

    getAllAccounts:    (state) -> state.get('accounts')

    getAccount:        (state, accountID) ->
        @getAllAccounts(state).get(accountID)

    getAccountByMailbox: (state, mailboxID) ->
        @getAllAccounts(state).find (account) ->
            account.get('mailboxes').get mailboxID

    getAllMailboxes:     (state, accountID) ->
        if accountID
            return @getAccount(state, accountID)?.get('mailboxes')

    getMailbox:        (state, mailboxID ) ->
        @getByMailbox(state, mailboxID)?.get('mailboxes').get(mailboxID)

    getByMailbox: (state, mailboxID) ->
        @getAllAccounts(state).find (account) ->
            # TODO There are some cases where account.get is not a function
            # this must be investigated
            return account.get?('mailboxes').get(mailboxID)


    # Legacy AccountStore mapping
    getById: (state, accountID) -> @getAccount(state, accountID)
    getByID: (state, accountID) -> @getAccount(state, accountID)

    getDefault: (state, mailboxID) ->
        return @getByMailbox(state, mailboxID) if mailboxID
        return @getAllAccounts(state).first()


    getMailboxOrder: (state, accountID, mailboxID) ->
        return DEFAULTORDER unless accountID and mailboxID
        return @getMailbox(state, mailboxID).get 'order'


    getByLabel: (state, label) ->
        state.get('accounts')?.find (account) ->
            account.get('label') is label


    isInbox: (state, accountID, mailboxID, getChildren=false) ->
        mailbox = @getMailbox state, mailboxID
        account = @getById(state, accountID)
        inboxMailbox = @getMailbox state, account.get('inboxMailbox')
        return mailbox is inboxMailbox or
               getChildren and mailbox.childOf(inboxMailbox)


    getInbox: (state, accountID) ->
        @getAllMailboxes(state, accountID)?.find (mailbox) =>
            @isInbox state, accountID, mailbox.get 'id'


    isTrashbox: (state, accountID, mailboxID) ->
        trashboxID = @getAccount(state, accountID)?.get 'trashMailbox'
        trashboxID is mailboxID


    getAllMailbox: (state, accountID) ->
        @getAllMailboxes(state, accountID)?.find (mailbox) ->
            -1 < mailbox.get('attribs')?.indexOf MailboxFlags.ALL
