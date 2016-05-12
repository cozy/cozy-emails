Immutable = require 'immutable'
_ = require 'lodash'

Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'


class AccountStore extends Store

    ###
        Defines private variables here.
    ###
    _accounts = Immutable.Iterable()


    _isInbox = (label) ->
        'inbox' is label.toLowerCase()


    _isSpecialMailbox = (label) ->
        _.find ['draft', 'sent', 'trash'], (tag) ->
            (new RegExp tag).test label.toLowerCase()


    _toImmutable = (account) ->

        # Do not get NoSelect mailbox
        # cf https://tools.ietf.org/html/rfc3501#page-69
        mailboxes = _.filter account.mailboxes, (mailbox) ->
            -1 is mailbox.attribs.indexOf '\\Noselect'

        account.mailboxes = Immutable.Iterable mailboxes
        .toKeyedSeq()
        .mapKeys (_, mailbox) -> mailbox.id
        .sort (mailbox) ->
            return 0 if _isInbox mailbox.tree[0]
            return 1 if _isSpecialMailbox mailbox.tree[0]
            return 2
        .map (mailbox) ->
            mailbox.depth = mailbox.tree.length - 1
            delete mailbox.tree
            Immutable.Map mailbox
        .toOrderedMap()

        delete account.totalUnread
        return Immutable.Map account


    # Creates an OrderedMap of accounts
    # this map will contains the base information for an account
    _initialize = ->
        _accounts = Immutable.Iterable window.accounts
            .toKeyedSeq()

            # sort first
            .sort (mb1, mb2) -> mb1.label.localeCompare mb2.label

            # sets account ID as index
            .mapKeys (_, account) -> account.id

            # makes account object an immutable Map
            .map _toImmutable

            .toOrderedMap()


    _getByMailbox = (mailboxID) ->
        _accounts?.find (account) ->
            account.get('mailboxes').get mailboxID


    _updateMailbox = (data) ->
        mailboxID = data.id
        account = _getByMailbox mailboxID
        if (accountID = account?.get 'id')
            mailboxes = account.get 'mailboxes'
            mailbox = mailboxes?.get(mailboxID) or Immutable.Map()

            for field, value of data
                mailbox = mailbox.set field, value

            if mailbox isnt mailboxes.get mailboxID
                mailboxes = mailboxes.set mailboxID, mailbox

                # FIXME : is attaching mailboxes to account usefull?
                account = account.set 'mailboxes', mailboxes

                _accounts = _accounts.set accountID, account


    _updateAccount = (rawAccount) ->
        account = AccountTranslator.toImmutable rawAccount
        accountID = account.get 'id'
        _accounts = _accounts?.set accountID, account



    ###
        Initialize private variables here.
    ###
    _initialize()


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->

        handle ActionTypes.ADD_ACCOUNT_SUCCESS, ({account}) ->
            _updateAccount account
            @emit 'change'


        handle ActionTypes.EDIT_ACCOUNT_SUCCESS, ({rawAccount}) ->
            _updateAccount rawAccount
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
            @emit 'change'


        handle ActionTypes.RECEIVE_MAILBOX_UPDATE, (mailbox) ->
            _updateMailbox mailbox
            @emit 'change'


    ###
        Public API
    ###
    getAll: ->
        _accounts


    getByID: (accountID) ->
        _accounts?.get accountID


    getDefault: (mailboxID) ->
        if mailboxID
            return @getByMailbox mailboxID
        else
            return @getAll().first()


    getByMailbox: (mailboxID) ->
        _getByMailbox mailboxID


    getByLabel: (label) ->
        _accounts?.find (account) ->
            account.get('label') is label


    getAllMailboxes: (accountID) ->
        if accountID
            _accounts?.get accountID
                .get 'mailboxes'


    makeEmptyAccount: ->
        Immutable.Map
            label: ''
            login: ''
            password: ''
            imapServer: ''
            imapLogin: ''
            smtpServer: ''
            label: ''
            id: null
            smtpPort: 465
            smtpSSL: true
            smtpTLS: false
            smtpMethod: 'PLAIN'
            imapPort: 993
            imapSSL: true
            imapTLS: false
            accountType: 'IMAP'
            favoriteMailboxes: null


module.exports = new AccountStore()
