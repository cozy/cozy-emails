module.exports =

    getAllAccounts:    (state) -> state.get('accounts')

    getAccount:        (state, accountID) ->
        @getAllAccounts(state).get(accountID)

    getAccountByMailbox: (state, mailboxID) ->
        @getAllAccounts(state).find (account) ->
            account.get('mailboxes').get mailboxID

    getAllMailboxes:     (state, accountID) ->
        @getAccount(state, accountID).get('mailboxes')

    getMailbox:        (state, mailboxID ) ->
        mailbox = null
        @getAllAccounts(state).find (account) ->
            mailbox = account.get('mailboxes').get(mailboxID)

        return mailbox
