Immutable = require 'immutable'

{ActionTypes} = require '../constants/app_constants'

Account = require '../models/account'
Mailbox = require '../models/mailbox'

DEFAULT_STATE = Immutable.Map()

_updateMailbox = (accounts, mailbox) ->

    if mailbox.accountID
        account = accounts.get(mailbox.accountID)
    else
        account = accounts.find (account) ->
            return account.get('mailboxes').get mailbox.id

    return accounts unless account

    mailbox = Mailbox.from mailbox, account
    return accounts unless mailbox

    return accounts.set account.get('id'), account.addMailbox(mailbox)


module.exports = (state=DEFAULT_STATE, action) ->

    switch action.type
        when ActionTypes.RESET_ACCOUNT_REQUEST
            return Immutable.Map()

        when ActionTypes.ADD_ACCOUNT_SUCCESS
            account = Account.from(action.value.account)
            return state.set(account.get('id'), account)

        when ActionTypes.RECEIVE_ACCOUNT_UPDATE
            account = Account.from(action.value)
            return state.set(account.get('id'), account)

        when ActionTypes.EDIT_ACCOUNT_SUCCESS
            account = Account.from(action.value.rawAccount)
            return state.set(account.get('id'), account)

        when ActionTypes.MAILBOX_DELETE_SUCCESS
            return state.set(account.get('id'), action.value)

        when ActionTypes.REMOVE_ACCOUNT_SUCCESS
            return state.delete action.value.accountID

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
