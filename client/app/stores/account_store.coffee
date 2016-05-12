Immutable = require 'immutable'

Store = require '../libs/flux/store/store'

{ActionTypes} = require '../constants/app_constants'


class AccountStore extends Store

    ###
        Defines private variables here.
    ###
    _accounts = Immutable.Iterable()

    _sortMailbox = (mailbox) ->
        last = {}
        weight1 = 900
        weight2 = 400

        mailbox.depth = mailbox.tree.length - 1

        # fake weight for sort
        if mailbox.depth is 0
            if 'inbox' is (label = mailbox.label.toLowerCase())
                mailbox.weight = 1000

            else if (mailbox.attribs.length > 0 or
                    /draft/.test(label) or
                    /sent/.test(label) or
                    /trash/.test(label))
                mailbox.weight = weight1
                weight1 -= 5

            else
                mailbox.weight = weight2
                weight2 -= 5

            last[mailbox.depth] = mailbox.weight
        else
            mailbox.weight = last[mailbox.depth - 1] - 0.1
            last[mailbox.depth] = mailbox.weight

        mailbox


    _toImmutable = (account) ->
        # Creates Immutable OrderedMap of mailboxes
        mailboxes = Immutable.Iterable account.mailboxes
        .toKeyedSeq()
        .mapKeys (_, mailbox) -> mailbox.id

        # Sort mailboxes by depth
        .map (mailbox) -> Immutable.Map _sortMailbox mailbox
        .toOrderedMap()

        delete account.totalUnread
        account.mailboxes = mailboxes
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


    _mailboxSort = (mb1, mb2) ->
        w1 = mb1.get 'weight'
        w2 = mb2.get 'weight'
        if w1 < w2 then return 1
        else if w1 > w2 then return -1
        else
            if mb1.get 'label' < mb2.get 'label' then return 1
            else if mb1.get 'label' > mb2.get 'label' then return -1
            else return 0


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
                .sort _mailboxSort


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
