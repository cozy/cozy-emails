Immutable = require 'immutable'
_ = require 'lodash'

Store = require '../libs/flux/store/store'

{ActionTypes, MailboxFlags, MailboxSpecial} = require '../constants/app_constants'

class AccountStore extends Store

    ###
        Defines private variables here.
    ###
    _accounts = Immutable.Iterable()


    # Get Mailbox Sort Order
    # These special mailbox should always appears on top
    # in the same order
    _getMailboxIndex = (mailbox) ->
        parent = mailbox.tree[0].toLowerCase()
        order = ['inbox', 'draft', 'sent', 'deleted', 'trash']
        index = _.findIndex order, (pattern) ->
            -1 < parent.indexOf pattern
        if -1 < index then ++index else order.length


    _toImmutable = (account) ->
        mailboxes = _.filter account.mailboxes, (mailbox) ->
            # Gmail issue:
            # no shortcuts into account
            # to specialMailboxes
            # TODO: should be done server side
            _.forEach MailboxSpecial, (type, value) ->
                unless account[value]?
                    if mailbox.attribs? and \
                    mailbox.attribs.length > 0 \
                    and MailboxFlags[type] is mailbox.attribs.join(',')
                        account[value] = mailbox.id

                    # Gmail Inbox has /noselect attribs
                    # but this flag is for no-catch-mailbox
                    # change attribs
                    else if 'INBOX' is type and -1 < ['INBOX', '[Gmail]'].indexOf mailbox.label
                        mailbox.attribs = [MailboxFlags[type]]
                        account[value] = mailbox.id

            # OVH issue
            # mailboxes has 2 mailbox called INBOX
            # but only one the the real one
            # remove the fake one
            # TODO: should be done server side
            if 'inbox' is mailbox.label.toLowerCase()
                mailbox.attribs = [MailboxFlags['INBOX']]
                return account.inboxMailbox is mailbox.id

            return true

        account.mailboxes = Immutable.Iterable mailboxes
        .toKeyedSeq()
        .mapKeys (_, mailbox) -> mailbox.id
        .sort (mb1, mb2) ->
            if mb1.tree[0] isnt mb2.tree[0]
                index1 = _getMailboxIndex mb1
                index2 = _getMailboxIndex mb2
                if index1 > index2
                    return 1
                else if index1 < index2
                    return -1

            # Ordering by path
            path1 = mb1.tree.join('/').toLowerCase()
            path2 = mb2.tree.join('/').toLowerCase()
            path1.localeCompare path2

        .map (mailbox, index) -> Immutable.Map mailbox
        .toOrderedMap()

        delete account.totalUnread
        return Immutable.Map account


    # Creates an OrderedMap of accounts
    # this map will contains the base information for an account
    _initialize = ->
        _accounts = Immutable.Iterable(window?.accounts or [])
            .toKeyedSeq()

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
        account = _toImmutable rawAccount
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


        handle ActionTypes.RECEIVE_ACCOUNT_UPDATE, (rawAccount) ->
            _updateAccount rawAccount
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


        handle ActionTypes.RECEIVE_MAILBOX_CREATE, (mailbox) ->
            _updateMailbox mailbox
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
        account = @getByMailbox mailboxID if mailboxID
        account ?= @getAll().first()
        account


    getByMailbox: (mailboxID) ->
        _getByMailbox mailboxID


    getByLabel: (label) ->
        _accounts?.find (account) ->
            account.get('label') is label


    getMailbox: (accountID, mailboxID) ->
        @getAllMailboxes(accountID)?.find (mailbox) ->
            mailboxID is mailbox.get 'id'


    getAllMailboxes: (accountID) ->
        if accountID
            _accounts?.get accountID
                .get 'mailboxes'


    isInbox: (accountID, mailboxID, getChildren=false) ->
        mailbox = @getMailbox accountID, mailboxID
        return unless mailbox?.size

        tree = mailbox.get('tree')
        tree = unless getChildren then tree.join('/') else tree[0]
        root = tree.toLowerCase()

        isInbox = 'inbox' is root
        isInboxChild = unless getChildren then tree.length is 1 else true
        isGmailInbox = '[gmail]' is root and isInboxChild

        return isInbox or isGmailInbox


    getInbox: (accountID) ->
        @getAllMailboxes(accountID)?.find (mailbox) =>
            @isInbox accountID, mailbox.get 'id'


    isTrashbox: (accountID, mailboxID) ->
        trashboxID = @getByID(accountID)?.get 'trashMailbox'
        trashboxID is mailboxID


    getAllMailbox: (accountID) ->
        @getAllMailboxes(accountID)?.find (mailbox) ->
            -1 < mailbox.get('attribs').indexOf MailboxFlags['ALL']


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

