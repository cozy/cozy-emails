Store = require '../libs/flux/store/Store'

{ActionTypes} = require '../constants/AppConstants'

class AccountStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Recursively creates Immutable OrderedMap of mailboxes
    createImmutableMailboxes = (children) ->
        Immutable.Sequence children
            .mapKeys (_, mailbox) -> mailbox.id
            .map (mailbox) ->
                mailbox.children = createImmutableMailboxes mailbox.children
                return Immutable.Map mailbox
            .toOrderedMap()

    # Creates an OrderedMap of accounts
    _accounts = Immutable.Sequence window.accounts

        # sort first
        .sort (mb1, mb2) ->
            if mb1.label > mb2.label then return 1
            else if mb1.label < mb2.label then return -1
            else return 0

        # sets account ID as index
        .mapKeys (_, account) -> return account.id

        # makes account object an immutable Map
        .map (account) ->
            account.mailboxes = createImmutableMailboxes account.mailboxes
            return Immutable.Map account

        .toOrderedMap()

    _selectedAccount = null
    _newAccountWaiting = false
    _newAccountError = null


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.ADD_ACCOUNT, (account) ->
            account = Immutable.Map account
            _accounts = _accounts.set account.get('id'), account
            @emit 'change'

        handle ActionTypes.SELECT_ACCOUNT, (accountID) ->
            _selectedAccount = _accounts.get(accountID) or null
            @emit 'change'

        handle ActionTypes.NEW_ACCOUNT_WAITING, (payload) ->
            _newAccountWaiting = payload
            @emit 'change'

        handle ActionTypes.NEW_ACCOUNT_ERROR, (error) ->
            _newAccountError = error
            @emit 'change'

        handle ActionTypes.EDIT_ACCOUNT, (account) ->
            account = Immutable.Map account
            _accounts = _accounts.set account.get('id'), account
            _selectedAccount = _accounts.get account.get 'id'
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT, (accountID) ->
            _accounts = _accounts.delete accountID
            _selectedAccount = @getDefault()
            @emit 'change'

    ###
        Public API
    ###
    getAll: -> return _accounts

    getDefault: -> return _accounts.first() or null

    getSelected: -> return _selectedAccount

    getSelectedMailboxes: ->
        return _selectedAccount?.get('mailboxes') or Immutable.Set.empty()

    getSelectedMailbox: (selectedID) ->
        mailboxes = @getSelectedMailboxes()
        if selectedID?
            return mailboxes.get selectedID
        else
            return mailboxes.first()

    # Takes the 3 first mailboxes to show as "favorite".
    # Skip the first 1, assumed to be the inbox
    # Should be made configurable.
    getSelectedFavorites: () ->
        return @getSelectedMailboxes()
            .skip 1
            .take 3
            .toOrderedMap()

    getError: -> return _newAccountError

    isWaiting: -> return _newAccountWaiting

module.exports = new AccountStore()
