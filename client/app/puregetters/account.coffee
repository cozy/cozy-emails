{MailboxFlags} = require '../constants/app_constants'
AccountMapper = require '../libs/mappers/account'

module.exports =

    getAllAccounts:    (state) ->
        state.account.get('accounts')

    getAccount:        (state, accountID) ->
        @getAllAccounts(state).get(accountID)

    getAccountByMailbox: (state, mailboxID) ->
        @getAllAccounts(state).find (account) ->
            account.get('mailboxes').get mailboxID

    getAllMailboxes:     (state, accountID) ->
        if accountID
            return @getAccount(state, accountID)?.get('mailboxes')

    getMailbox:        (state, mailboxID ) ->
        mailbox = null
        @getAllAccounts(state).find (account) ->
            # TODO There are some cases where account.get is not a function
            # this must be investigated
            if typeof account.get is 'function'
                mailbox = account.get('mailboxes').get(mailboxID)

        return mailbox


    # Legacy AccountStore mapping
    getById: (state, accountID) ->
        return state.account
            .get 'accounts'
            .get accountID

    getDefault: (state, mailboxID) ->
        return @getMailbox(state, mailboxID) if mailboxID
        return @getAllAccounts(state).first()


    getMailboxOrder: (state, accountID, mailboxID) ->
        return state.account.get 'mailboxOrder' unless accountID and mailboxID
        return @getMailbox(state, mailboxID).get 'order'


    getByLabel: (state, label) ->
        state.account.get('accounts')?.find (account) ->
            account.get('label') is label


    getAccountByMailbox: (state, mailboxID) ->
        @getAllAccounts(state)?.find (account) ->
            account.get('mailboxes').get mailboxID


    # Temporary code duplication, should be in an util/service library
    isGmail: (account) ->
        -1 < account?.label?.toLowerCase().indexOf 'gmail'


    isInbox: (state, accountID, mailboxID, getChildren=false) ->
        return false unless (mailbox = @getMailbox state, mailboxID)?.size

        account = @getById(state, accountID)?.toObject()
        attribs = mailbox.get('attribs')
        attribs = unless getChildren then attribs?.join('/') else attribs?[0]

        isInbox = MailboxFlags.INBOX is attribs
        isInboxChild = unless getChildren then attribs?.length is 1 else true
        isGmailInbox = @isGmail(account) and isInboxChild

        return isInbox or isGmailInbox


    getInbox: (state, accountID) ->
        @getAllMailboxes(state, accountID)?.find (mailbox) =>
            @isInbox state, accountID, mailbox.get 'id'


    isTrashBox: (state, accountID, mailboxID) ->
        trashboxID = @getAccount(state, accountID)?.get 'trashMailbox'
        trashboxID is mailboxID


    getAllMailbox: (state, accountID) ->
        @getAllMailboxes(state, accountID)?.find (mailbox) ->
            -1 < mailbox.get('attribs')?.indexOf MailboxFlags.ALL
