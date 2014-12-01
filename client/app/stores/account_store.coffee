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

    _selectedAccount   = null
    _selectedMailbox   = null
    _newAccountWaiting = false
    _newAccountError   = null



    getMailbox = (accountID, boxID) ->
        _accounts.get(accountID)?.get(boxID)

    setMailbox = (accountID, boxID, boxData) ->

        account = _accounts.get(accountID)
        mailboxes = account.get('mailboxes')
        mailboxes = mailboxes.map (box) ->
            if box.get('id') is boxID
                AccountTranslator.mailboxToImmutable boxData
            else
                box
        .toOrderedMap()

        account = account.set 'mailboxes', mailboxes
        _accounts = _accounts.set accountID, account

        if selectedAccountID = _selectedAccount?.get 'id'
            _selectedAccount = _accounts.get selectedAccountID
            if selectedMailboxID = _selectedMailbox?.get 'id'
                _selectedMailbox = _selectedAccount
                    ?.get('mailboxes')
                    ?.get(selectedMailboxID)

    _setCurrentAccount: (account) ->
        _selectedAccount = account
    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        onUpdate = (rawAccount) =>
            account = AccountTranslator.toImmutable rawAccount
            _accounts = _accounts.set account.get('id'), account
            @_setCurrentAccount account
            _newAccountWaiting = false
            _newAccountError   = null
            @emit 'change'

        handle ActionTypes.ADD_ACCOUNT, (rawAccount) ->
            onUpdate rawAccount

        handle ActionTypes.SELECT_ACCOUNT, (value) ->
            if value.accountID?
                @_setCurrentAccount(_accounts.get(value.accountID) or null)
            else
                @_setCurrentAccount(null)
            if value.mailboxID?
                _selectedMailbox = _selectedAccount?.get('mailboxes')?.get(value.mailboxID) or null
            else
                _selectedMailbox = null
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
            @_setCurrentAccount @getDefault()
            @emit 'change'

        handle ActionTypes.RECEIVE_MAILBOX_UPDATE, (boxData) ->
            setMailbox boxData.accountID, boxData.id, boxData
            @emit 'change'

    ###
        Public API
    ###
    getAll: -> return _accounts

    getByID: (accountID) ->
        return _accounts.get accountID

    getByLabel: (label) ->
        _accounts.find (account) -> account.get('label') is label

    getDefault: -> return _accounts.first() or null

    getDefaultMailbox: (accountID) ->

        account = _accounts.get(accountID) or @getDefault()
        return null unless account

        mailboxes = account.get('mailboxes')
        mailbox = mailboxes.filter (mailbox) ->
            return mailbox.get('label').toLowerCase() is 'inbox'
        if mailbox.count() isnt 0
            return mailbox.first()
        else
            favorites = account.get('favorites')
            defaultID = if favorites? then favorites[0]

            return if defaultID then mailboxes.get defaultID
            else mailboxes.first()

    getSelected: -> return _selectedAccount

    getSelectedMailboxes: ->

        return Immutable.OrderedMap.empty() unless _selectedAccount?

        result = Immutable.OrderedMap()
        _selectedAccount.get('mailboxes').forEach (data) ->
            mailbox = Immutable.Map data
            result = result.set mailbox.get('id'), mailbox
            return true

        return result


    getSelectedMailbox: (selectedID) ->
        mailboxes = @getSelectedMailboxes()
        if selectedID?
            return mailboxes.get selectedID
        else
            return mailboxes.first()

    getSelectedFavorites: ->

        mailboxes = @getSelectedMailboxes()
        ids = _selectedAccount?.get 'favorites'

        if ids?
            return mailboxes
                .filter (box, key) -> key in ids
                .toOrderedMap()
        else
            return mailboxes
                .toOrderedMap()

    getError: -> return _newAccountError

    isWaiting: -> return _newAccountWaiting


module.exports = new AccountStore()
