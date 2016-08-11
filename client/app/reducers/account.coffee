Immutable = require 'immutable'

AccountGetter = require '../getters/account'

{ActionTypes, MailboxFlags, MailboxSpecial} = require '../constants/app_constants'

DEFAULT_STATE = Immutable.Map
    accounts: null
    # Should definetly be in view or settings file.
    mailboxOrder: 100

module.exports = (state=DEFAULT_STATE, action) ->

    # Update an account in the state accounts Map.
    _updateAccount = (state, account) ->
        # throw error when account has no id ?
        accounts = state.get 'accounts'
        accounts = accounts.set account.id, account
        return state.set 'accounts', accounts


    # Delete an account in the accounts Map
    _deleteAccount = (state, account) ->
        # throw error when account has no id ?
        accounts = state.get 'accounts'
        accounts = accounts.delete account.id
        return state.set 'accounts', accounts


    _updateMailbox = (state, mailbox) ->
        # throw error when maibox has no id
        unless (account = AccountGetter.getByMailbox state, mailbox.id)?
            accountID = mailbox.accountID or _accounts?.first()?.get 'id'
            account = _accounts?.get(accountID)
            return state unless account?

        return state unless (mailbox = AccountMapper.formatMailbox account.toJS(), mailbox)
        return state unless AccountMapper.filterDuplicateMailbox account.toJS(), mailbox

        mailboxes = account.get('mailboxes')
        mailboxes = mailboxes.set mailbox.id, Immutable.OrderedMap mailbox
        account = account.set 'mailboxes', mailboxes
        _updateAccount state, account


    switch action.type
        when ActionTypes.RESET_ACCOUNT_REQUEST
            nextstate = state.set 'accounts', Immutable.Map()

        when ActionTypes.ADD_ACCOUNT_SUCCESS
            nextstate = _updateAccount state, action.value.account

        when ActionTypes.RECEIVE_ACCOUNT_UPDATE
            nextstate = _updateAccount state, action.value

        when ActionTypes.EDIT_ACCOUNT_SUCCESS
            nextstate = _updateAccount state, action.value.rawAccount

        when ActionTypes.MAILBOX_DELETE_SUCCESS
            nextstate = _updateAccount state, action.value

        when ActionTypes.REMOVE_ACCOUNT_SUCCESS
            nextstate = _deleteAccount state, action.value

        when ActionTypes.MAILBOX_CREATE_SUCCESS
            nextstate = _updateMailbox state, action.value

        when ActionTypes.RECEIVE_MAILBOX_CREATE
            nextstate = _updateMailbox state, action.value

        when ActionTypes.MAILBOX_UPDATE_SUCCESS
            nextstate = _updateMailbox state, action.value

        when ActionTypes.RECEIVE_MAILBOX_UPDATE
            nextstate = _updateMailbox state, action.value

        when ActionTypes.MAILBOX_EXPUNGE
            # TODO: should update account counter
            # if a mailbox came empty
            # - mailbox.nbTotal should be equal to 0
            # - account.nbTotal shoudl also be updated: missing args to do this
            nextstate = state


    return nextstate or state
