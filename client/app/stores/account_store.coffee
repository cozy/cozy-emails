_         = require 'underscore'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

RouterGetter = require '../getters/router'

{ActionTypes, AccountActions} = require '../constants/app_constants'

AccountTranslator = require '../utils/translators/account_translator'

cachedTransform = require '../libs/cached_transform'

STATICBOXFIELDS = ['id', 'accountID', 'label', 'tree', 'weight']
CHANGEBOXFIELDS = ['lastSync', 'nbTotal', 'nbUnread', 'nbRecent']

class AccountStore extends Store

    ###
        Initialization.
        Defines private variables here.
    ###

    # Creates an OrderedMap of accounts
    # this map will contains the base information for an account
    _accounts = Immutable.Iterable window.accounts
        .toKeyedSeq()

        # sort first
        .sort (mb1, mb2) -> mb1.label.localeCompare mb2.label

        # sets account ID as index
        .mapKeys (_, account) -> account.id

        # makes account object an immutable Map
        .map (account) -> AccountTranslator.toImmutable account

        .toOrderedMap()

    _accountID = null
    _mailboxID = null

    _newAccountWaiting = false
    _newAccountChecking = false

    _serverAccountErrorByField = Immutable.Map()

    _tab = null

    _clearError = ->
        _serverAccountErrorByField = Immutable.Map()
    _addError = (field, err) ->
        _serverAccountErrorByField = _serverAccountErrorByField.set field, err

    _checkForNoMailbox = (rawAccount) ->
        unless rawAccount.mailboxes?.length > 0
            _setError
                name: 'AccountConfigError',
                field: 'nomailboxes'
                causeFields: ['nomailboxes']

    _setError = (error) ->
        if error.name is 'AccountConfigError'
            clientError =
                message: t "config error #{error.field}"
                originalError: error.originalError
                originalErrorStack: error.originalErrorStack
            errorsMap = {}
            errorsMap[field] = clientError for field in error.causeFields
            _serverAccountErrorByField = Immutable.Map errorsMap

        else
            _serverAccountErrorByField = Immutable.Map "unknown": error


    _setMailbox = (data) ->
        # on account creation, sometime socket send mailboxes updates
        # before the account has been saved locally
        return true unless (account = _accounts.get _accountID)

        mailboxID = data.id
        mailboxes = account.get('mailboxes')
        mailbox = mailboxes.get(mailboxID) or Immutable.Map()

        data.weight = mailbox.get 'weight' if mailbox.get 'weight'

        for field of STATICBOXFIELDS when mailbox.get(field) isnt data[field]
            mailbox = mailbox.set field, data[field]

        if mailbox isnt mailboxes.get mailboxID
            mailboxes = mailboxes.set mailboxID, mailbox
            account = account.set 'mailboxes', mailboxes
            _accounts = _accounts.set accountID, account

    _mailboxSort = (mb1, mb2) ->
        w1 = mb1.get 'weight'
        w2 = mb2.get 'weight'
        if w1 < w2 then return 1
        else if w1 > w2 then return -1
        else
            if mb1.get 'label' < mb2.get 'label' then return 1
            else if mb1.get 'label' > mb2.get 'label' then return -1
            else return 0


    _setCurrentAccount = (accountID, mailboxID) ->
        _accountID = accountID
        _mailboxID = mailboxID

    _onAccountUpdated: (rawAccount) ->
        account = AccountTranslator.toImmutable rawAccount
        accountID = account.get 'id'

        _accounts = _accounts.set accountID, account
        _setCurrentAccount accountID


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        # handle ActionTypes.SELECT_ACCOUNT, (value) ->
        handle ActionTypes.ROUTE_CHANGE, (value) ->
            mailboxID = @getSelectedMailbox()?.get 'id'
            accountID = @getSelectedOrDefault()?.get 'id'

            if accountID
                @_setCurrentAccount(_accounts.get(value.accountID) or null)
            else
                @_setCurrentAccount(null)

            if mailboxID
                mailbox = _selectedAccount
                ?.get('mailboxes')
                ?.get(value.mailboxID) or null
                @_setCurrentMailbox mailbox
            else
                _clearError()
                @_setCurrentMailbox null

            if value.action is AccountActions.EDIT and not _tab = params.tab
                mailboxes = @getSelected()?.get 'mailboxes'
                _tab = if mailboxes?.size is 0 then 'mailboxes' else 'account'

            @emit 'change'

        handle ActionTypes.ADD_ACCOUNT_REQUEST, ({inputValues}) ->
            _newAccountWaiting = true
            @emit 'change'

        handle ActionTypes.ADD_ACCOUNT_SUCCESS, ({account}) ->
            _newAccountWaiting = false
            _checkForNoMailbox account
            @_onAccountUpdated account
            @emit 'change'

        handle ActionTypes.ADD_ACCOUNT_FAILURE, ({error}) ->
            _newAccountWaiting = false
            _setError error
            @emit 'change'

        handle ActionTypes.CHECK_ACCOUNT_REQUEST, () ->
            _newAccountChecking = true
            @emit 'change'

        handle ActionTypes.CHECK_ACCOUNT_SUCCESS, () ->
            _newAccountChecking = false
            @emit 'change'

        handle ActionTypes.CHECK_ACCOUNT_FAILURE, ({error}) ->
            _newAccountChecking = false
            _setError error
            @emit 'change'


        handle ActionTypes.EDIT_ACCOUNT_REQUEST, ({inputValues}) ->
            _newAccountWaiting = true
            @emit 'change'


        handle ActionTypes.EDIT_ACCOUNT_SUCCESS, ({rawAccount}) ->
            _newAccountWaiting = false
            _clearError()
            _checkForNoMailbox rawAccount
            @_onAccountUpdated rawAccount
            @emit 'change'

        handle ActionTypes.EDIT_ACCOUNT_FAILURE, ({error}) ->
            _newAccountWaiting = false
            _setError error
            @emit 'change'

        handle ActionTypes.MAILBOX_CREATE_SUCCESS, (rawAccount) ->
            @_onAccountUpdated rawAccount
            @emit 'change'

        handle ActionTypes.MAILBOX_UPDATE_SUCCESS, (rawAccount) ->
            @_onAccountUpdated rawAccount
            @emit 'change'

        handle ActionTypes.MAILBOX_DELETE_SUCCESS, (rawAccount) ->
            @_onAccountUpdated rawAccount
            @emit 'change'

        handle ActionTypes.MAILBOX_EXPUNGE_FAILURE, ({error, mailboxID, accountID}) ->
            # if user hasn't switched to another box, refresh display
            unless _mailboxID isnt mailboxID
                _mailboxID = mailboxID

        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, (accountID) ->
            _accounts = _accounts.delete accountID
            _setCurrentAccount()
            @emit 'change'

        handle ActionTypes.RECEIVE_MAILBOX_UPDATE, (mailbox) ->
            _setMailbox mailbox
            @emit 'change'

        handle ActionTypes.REFRESH_SUCCESS, ({accountID, mailboxID}) ->
            _setCurrentAccount accountID, mailboxID
            @emit 'change'


    ###
        Public API
    ###
    getAll: ->
        return _accounts


    getAllMailboxes: ->
        cachedTransform AccountStore, 'all-mailboxes', _accounts, ->
            _accounts.flatMap (account) -> account.get 'mailboxes'

    getSelectedTab: ->
        return _tab

    getByID: (accountID) ->
        return _accounts.get accountID


    getByLabel: (label) ->
        _accounts.find (account) -> account.get('label') is label


    getDefault: ->
        return _accounts.first() or null


    _getDefaultMailbox = ->
        return null unless (account = @getDefault())

        mailboxes = account.get('mailboxes')
        mailbox = mailboxes.filter (mailbox) ->
            return mailbox.get('label').toLowerCase() is 'inbox'

        if mailbox.size
            return mailbox.first()
        else
            favorites = account.get('favorites')
            defaultID = if favorites? then favorites[0]

            return if defaultID then mailboxes.get defaultID
            else mailboxes.first()


    getAccountID: ->
        return @getDefault()?.get 'id' unless _accountID
        return _accountID

    getMailboxID: ->
        _mailboxID

    getSelected: ->
        _accounts.get(_accountID) or @getDefault()

    getAllMailboxes: ->
        if _accountID?
            return _accounts.get(_accountID)
                .get('mailboxes')
                .sort(_mailboxSort)

    getMailbox: (selectedID) ->
        if (mailboxes = @getAllMailboxes())?.size
            selectedID ?= _mailboxID
            return mailboxes.get selectedID
        return _getDefaultMailbox()


    getErrors: -> _serverAccountErrorByField
    getRawErrors: -> _serverAccountErrorByField.get('unknown')
    getAlertErrorMessage: ->
        error = _serverAccountErrorByField.first()
        if error.name is 'AccountConfigError'
            return t "config error #{error.field}"
        else
            return error.message or error.name or error

    isWaiting: -> return _newAccountWaiting
    isChecking: -> return _newAccountChecking



module.exports = _self = new AccountStore()
