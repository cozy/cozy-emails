Immutable = require 'immutable'

{ActionTypes} = require '../constants/app_constants'

Account = require '../models/account'
Mailbox = require '../models/mailbox'

DEFAULT_STATE = Immutable.Map()


module.exports = (state=DEFAULT_STATE, action) ->

    switch action.type

        when ActionTypes.RESET_ACCOUNT_REQUEST
            return Immutable.Map()


        when ActionTypes.ADD_ACCOUNT_SUCCESS
            return _updateAccount state, action.value.account


        when ActionTypes.RECEIVE_ACCOUNT_UPDATE
            return _updateAccount state, action.value


        when ActionTypes.EDIT_ACCOUNT_SUCCESS
            return _updateAccount state, action.value.rawAccount


        when ActionTypes.MAILBOX_DELETE_SUCCESS
            return _updateAccount state, action.value


        when ActionTypes.REMOVE_ACCOUNT_SUCCESS
            return _deleteAccount state, action.value


        when ActionTypes.MAILBOX_CREATE_SUCCESS
            return _updateMailbox state, action.value


        when ActionTypes.RECEIVE_MAILBOX_CREATE
            return _updateMailbox state, action.value


        when ActionTypes.MAILBOX_UPDATE_SUCCESS
            return _updateMailbox state, action.value


        when ActionTypes.RECEIVE_MAILBOX_UPDATE
            return _updateMailbox state, action.value


        when ActionTypes.MAILBOX_EXPUNGE
            # TODO: should update account counter
            # if a mailbox came empty
            # - mailbox.nbTotal should be equal to 0
            # - account.nbTotal shoudl also be updated: missing args to do this
            return state

    return state


_updateAccount = (state, rawAccount) ->
    # Format rawAccount to AccountModel
    account = Account.from rawAccount
    accountID = account.get 'id'

    unless (accounts = state.get 'accounts')?.size
        accounts = Immutable.OrderedMap()

    accounts = accounts.set accountID, account
    state = state.set 'accounts', accounts

    return state


_deleteAccount = (state, account) ->
    accountID = account.accountID
    accounts = state.get('accounts').delete accountID
    return state.set 'accounts', accounts


_updateMailbox = (state, rawMailbox) ->
    unless (accounts = state.get 'accounts')?.size
        return state

    if rawMailbox.accountID
        account = accounts.get rawMailbox.accountID
    else
        account = accounts.find (account) ->
            return account.get('mailboxes').get rawMailbox.id

    # Format rawMailbox to MailboxModel
    mailbox = Mailbox.from rawMailbox, account

    if not account?.size or not mailbox?.size
        return state

    return _updateAccount state, account.addMailbox(mailbox)
