Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'

AccountTranslator = require '../utils/translators/account_translator'

class AccountStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

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
        .map (account) -> AccountTranslator.toImmutable account

        .toOrderedMap()

    _selectedAccount = null
    _newAccountWaiting = false
    _newAccountError = null


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        onUpdate = (rawAccount) =>
            accountID = rawAccount.id
            account = AccountTranslator.toImmutable rawAccount
            _accounts = _accounts.set accountID, account
            _selectedAccount = _accounts.get accountID
            _newAccountWaiting = false
            @emit 'change'

        handle ActionTypes.ADD_ACCOUNT, (account) ->
            account = AccountTranslator.toImmutable account
            _accounts = _accounts.set account.get('id'), account
            _selectedAccount = account
            _newAccountWaiting = false
            @emit 'change'

        handle ActionTypes.SELECT_ACCOUNT, (accountID) ->
            if accountID?
                _selectedAccount = _accounts.get(accountID) or null
            else
                _selectedAccount = null
            @emit 'change'

        handle ActionTypes.NEW_ACCOUNT_WAITING, (payload) ->
            _newAccountWaiting = payload
            @emit 'change'

        handle ActionTypes.NEW_ACCOUNT_ERROR, (error) ->
            _newAccountWaiting = false
            _newAccountError = error
            @emit 'change'

        handle ActionTypes.EDIT_ACCOUNT, (rawAccount) ->
            onUpdate rawAccount

        handle ActionTypes.MAILBOX_CREATE, (rawAccount) ->
            onUpdate rawAccount

        handle ActionTypes.MAILBOX_UPDATE, (rawAccount) ->
            onUpdate rawAccount

        handle ActionTypes.MAILBOX_DELETE, (rawAccount) ->
            onUpdate rawAccount

        handle ActionTypes.REMOVE_ACCOUNT, (accountID) ->
            _accounts = _accounts.delete accountID
            _selectedAccount = @getDefault()
            @emit 'change'

    ###
        Public API
    ###
    getAll: -> return _accounts

    getByID: (accountID) -> return _accounts.get accountID

    getByLabel: (label) ->
        _accounts.find (account) -> account.get('label') is label

    getDefault: -> return _accounts.first() or null

    getDefaultMailbox: (accountID) ->

        account = _accounts.get(accountID) or @getDefault()
        mailboxes = account.get('mailboxes')
        favorites = account.get('favorites')
        defaultID = if favorites? then favorites[0]

        return if defaultID then mailboxes.get defaultID
        else mailboxes.first()

    getSelected: -> return _selectedAccount

    getSelectedMailboxes: (flatten = false) ->

        return Immutable.OrderedMap.empty() unless _selectedAccount?

        if flatten
            rawMailboxesTree = _selectedAccount.get('mailboxes').toJS()
            # @FIXME Should be done with iterator when they are fixed
            getFlattenMailboxes = (childrenMailboxes, depth = 0) ->
                result = Immutable.OrderedMap()
                for id, rawMailbox of childrenMailboxes
                    children = rawMailbox.children
                    delete rawMailbox.children
                    mailbox = Immutable.Map rawMailbox
                    # we add a depth indicator for display
                    mailbox = mailbox.set 'depth', depth
                    result = result.set mailbox.get('id'), mailbox
                    result = result.merge getFlattenMailboxes children, \
                                                                    (depth + 1)
                return result.toOrderedMap()

            return getFlattenMailboxes(rawMailboxesTree).toOrderedMap()
        else
            emptyMap = Immutable.OrderedMap.empty()
            return _selectedAccount?.get('mailboxes') or emptyMap

    getSelectedMailbox: (selectedID) ->
        mailboxes = @getSelectedMailboxes()
        if selectedID?
            return mailboxes.get selectedID
        else
            return mailboxes.first()

    # Takes the 3 first mailboxes to show as "favorite".
    # Skip the first 1, assumed to be the inbox
    # Should be made configurable.
    getSelectedFavorites: ->


        mailboxes = @getSelectedMailboxes true
        ids = _selectedAccount?.get 'favorites'

        if ids?
            return mailboxes
                .filter (box, key) -> key in ids[1..]
                .toOrderedMap()
        else
            return mailboxes
                .toOrderedMap()

    getError: -> return _newAccountError

    isWaiting: -> return _newAccountWaiting

module.exports = new AccountStore()
