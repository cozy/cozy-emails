reduxStore = require '../reducers/_store'
pure = require '../puregetters/account'

# Legacy with account store, temporary encapsulation for pure getter to
# facilitate redux migration
module.exports =

    getAll: ->
        pure.getAllAccounts reduxStore.getState()


    getByID: (accountID) ->
        pure.getAccount reduxStore.getState(), accountID


    getDefault: (mailboxID) ->
        pure.getDefault reduxStore.getState(), mailboxID


    getMailboxOrder: (accountID, mailboxID) ->
        pure.getMailboxOrder reduxStore.getState(), accountID, mailboxID


    getByMailbox: (mailboxID) ->
        pure.getAccountByMailbox reduxStore.getState(), mailboxID


    getByLabel: (label) ->
        pure.getByLabel reduxStore.getState(), label


    getMailbox: (accountID, mailboxID) ->
        @getByMailbox mailboxID


    getAllMailboxes: (accountID) ->
        pure.getAllMailboxes reduxStore.getState(), accountID


    isInbox: (accountID, mailboxID, getChildren=false) ->
        pure.isInbox reduxStore.getState(), accountID, mailboxID, getChildren


    getInbox: (accountID) ->
        pure.getInbox reduxStore.getState(), accountID


    isTrashbox: (accountID, mailboxID) ->
        pure.isTrashBox reduxStore.getState(), accountID, mailboxID


    getAllMailbox: (accountID) ->
        pure.getAllMailbox reduxStore.getState(), accountID
