_         = require 'underscore'
Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

RouterGetter = require '../getters/router'

{ActionTypes, AccountActions} = require '../constants/app_constants'

AccountTranslator = require '../utils/translators/account_translator'

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
        return true unless (account = _accounts.get _accountID)?.size

        mailboxID = data.id
        mailboxes = account.get('mailboxes')

        mailbox = mailboxes.get(mailboxID) or Immutable.Map()
        for field, value of data
            mailbox = mailbox.set field, value

        if mailbox isnt mailboxes.get mailboxID
            mailboxes = mailboxes.set mailboxID, mailbox

            # FIXME : is attaching mailboxes to account useless?
            account = account.set 'mailboxes', mailboxes

            _accounts = _accounts.set _accountID, account


    _mailboxSort = (mb1, mb2) ->
        w1 = mb1.get 'weight'
        w2 = mb2.get 'weight'
        if w1 < w2 then return 1
        else if w1 > w2 then return -1
        else
            if mb1.get 'label' < mb2.get 'label' then return 1
            else if mb1.get 'label' > mb2.get 'label' then return -1
            else return 0


    _setCurrentAccount = (accountID, mailboxID, tab="mailboxes") ->
        _accountID = accountID
        _mailboxID = mailboxID
        _tab = tab


    _updateAccount = (rawAccount) ->
        account = AccountTranslator.toImmutable rawAccount
        accountID = account.get 'id'
        _accounts = _accounts.set accountID, account


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.ROUTE_CHANGE, ({accountID, mailboxID, action, tab}) ->
            accountID ?= @getDefault(mailboxID)?.get('id') if mailboxID
            _setCurrentAccount accountID, mailboxID, tab

            @emit 'change'

        handle ActionTypes.ADD_ACCOUNT_REQUEST, ({value}) ->
            _newAccountWaiting = true
            @emit 'change'

        handle ActionTypes.ADD_ACCOUNT_SUCCESS, ({account}) ->
            _newAccountWaiting = false
            _checkForNoMailbox account
            _updateAccount account
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


        handle ActionTypes.EDIT_ACCOUNT_REQUEST, ({value}) ->
            _newAccountWaiting = true
            @emit 'change'


        handle ActionTypes.EDIT_ACCOUNT_SUCCESS, ({rawAccount}) ->
            _newAccountWaiting = false
            _clearError()
            _checkForNoMailbox rawAccount
            _updateAccount rawAccount
            @emit 'change'

        handle ActionTypes.EDIT_ACCOUNT_FAILURE, ({error}) ->
            _newAccountWaiting = false
            _setError error
            @emit 'change'

        handle ActionTypes.MAILBOX_CREATE_SUCCESS, (rawAccount) ->
            _updateAccount rawAccount
            @emit 'change'

        handle ActionTypes.MAILBOX_UPDATE_SUCCESS, (rawAccount) ->
            _updateAccount rawAccount
            @emit 'change'

        handle ActionTypes.MAILBOX_DELETE_SUCCESS, (rawAccount) ->
            _updateAccount rawAccount
            @emit 'change'

        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, (accountID) ->
            _accounts = _accounts.delete accountID
            _setCurrentAccount()
            @emit 'change'

        handle ActionTypes.RECEIVE_MAILBOX_UPDATE, (mailbox) ->
            _setMailbox mailbox
            @emit 'change'


    ###
        Public API
    ###
    getAll: ->
        return _accounts


    getSelectedTab: ->
        return _tab


    getByID: (accountID) ->
        return _accounts?.get accountID


    getByLabel: (label) ->
        _accounts.find (account) -> account.get('label') is label


    getDefault: (mailboxID) ->
        if mailboxID
            return _accounts.find (account) ->
                account.get('mailboxes').get(mailboxID)
        return _accounts.first()


    getAccountID: ->
        return @getDefault()?.get 'id' unless _accountID
        return _accountID


    getMailboxID: ->
        return @getDefault()?.get 'inboxMailbox' unless _mailboxID
        return _mailboxID


    getSelected: ->
        return _accounts?.get _accountID


    getAllMailboxes: (accountID) ->
        accountID ?= @getAccountID()
        return _accounts.get accountID
            .get 'mailboxes'
            .sort _mailboxSort


    getMailbox: (mailboxID) ->
        mailboxID ?= _mailboxID
        return @getAllMailboxes()?.get mailboxID


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
