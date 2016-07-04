Immutable = require 'immutable'
_ = require 'lodash'

Store = require '../libs/flux/store/store'

{ActionTypes, MailboxFlags, MailboxSpecial} = require '../constants/app_constants'

class AccountStore extends Store

    ###
        Defines private variables here.
    ###
    _accounts = null;
    _mailboxOrder = 100;


    _isGmail = (account) ->
        -1 < account.label?.toLowerCase().indexOf 'gmail'


    # Get Mailbox Sort Order
    # These special mailbox should always appears on top
    # in the same order
    _getMailboxOrder = ({attribs, tree, label, attrib}) ->
        if attribs?.length
            value = _.reduce attribs, (result, attrib) ->
                result.push index if -1 < (index = _getMailboxOrder {attrib})
                result
            , []
            if (index = value.shift())?
                index = "#{index}.#{decimal}" if (decimal = value.join '').length
                return index * 1

        else if attrib?
            index = _.findIndex _.keys(MailboxFlags), (key) -> MailboxFlags[key] is attrib
            return index if -1 < index

        return _mailboxOrder


    # FIXME: all this stuff should be done sever side
    # its only about fixing what server side part doesnt complete
    _formatMailbox = (account, mailbox) ->
        # Reset empty properties
        tree = if mailbox.tree? and not _.isEmpty _.compact mailbox.tree
        then mailbox.tree
        else undefined
        mailbox.tree = undefined unless tree?

        # Reset empty properties
        attribs = if mailbox.attribs? and not _.isEmpty _.compact mailbox.attribs
        then mailbox.attribs
        else undefined
        mailbox.attribs = undefined unless attribs?

        if _isGmail(account)
            # INBOX issue
            # delete INBOX and use [Gmail] instead
            # because [Gmail] is the root of all InboxChild tree
            if 'inbox' is (path = mailbox.tree?.join(',').toLowerCase())
                return

            # Gmail Inbox has /noselect attribs
            # but this flag isnt appropriate
            # since [Gmail] mailbox is flagged as INBOX
            # so that attribs should be [\Inbox] but not [\Noselect]
            isInbox = -1 < path.indexOf 'gmail'
            isAttribMissing = -1 is mailbox.attribs?.indexOf MailboxFlags.INBOX
            isChild = 1 < mailbox.tree?.length
            if isInbox and isAttribMissing
                # clean [Gmail].attribs
                unless isChild
                    delete mailbox.attribs
                    account.inboxMailbox = mailbox.id

                # Add missing \Inbox flag
                mailbox.attribs ?= []
                mailbox.attribs.unshift MailboxFlags.INBOX


        # Add appropriate attribs according to tree
        _.forEach MailboxSpecial, (type, value) ->
            type = [type] if _.isString type
            type.forEach (_type) ->
                return if -1 < mailbox.attribs?.indexOf MailboxFlags[_type]
                tree?.forEach (_tree) ->
                    # TODO: ajouter à attribs \inbox
                    # s'il contient le label de Inbox dans tree
                    if -1 < _tree.toLowerCase().indexOf _type.toLowerCase()
                        mailbox.attribs ?= []
                        mailbox.attribs.push MailboxFlags[type[0]]
                        account[value] ?= mailbox.id

        # Get order based on attribs value
        mailbox.order = _getMailboxOrder mailbox

        mailbox


    _filterMailbox = (account, mailbox) ->
        # OVH issue
        # mailboxes has 2 mailbox called INBOX
        # but only one the the real one
        # remove the fake one
        # TODO: should be done server side
        if _.isEqual mailbox.attribs, [MailboxFlags.INBOX]
            return mailbox.id is account.inboxMailbox
        else
            return true


    _toImmutable = (account) ->
        _account = _.cloneDeep account
        _mailboxes = _.compact _.map _account.mailboxes, (mailbox) ->
                _formatMailbox account, mailbox
            .filter (mailbox) ->
                _filterMailbox account, mailbox if mailbox

        _account.mailboxes = Immutable.Iterable _mailboxes
            .toKeyedSeq()
            .mapKeys (_, mailbox) -> mailbox.id
            .sort (mb1, mb2) ->
                if mb1.order > mb2.order
                    return 1
                else if mb1.order < mb2.order
                    return -1

                # Ordering by path
                if mb1.tree? and mb2.tree?
                    path1 = mb1.tree.join('/').toLowerCase()
                    path2 = mb2.tree.join('/').toLowerCase()
                    return path1.localeCompare path2

            .map (mailbox, index) -> Immutable.Map mailbox
            .toOrderedMap()

        delete _account.totalUnread
        return Immutable.Map _account


    # Creates an OrderedMap of accounts
    # this map will contains the base information for an account
    _initialize = ->
        _accounts = _.cloneDeep(window?.accounts) or []
        _accounts = Immutable.Iterable _accounts
            .toKeyedSeq()
            # sets account ID as index
            .mapKeys (_, account) -> account.id

            # makes account object an immutable Map
            .map _toImmutable

            .toOrderedMap()


    _getByMailbox = (mailboxID) ->
        _accounts?.find (account) ->
            account.get('mailboxes').get mailboxID


    _updateMailbox = (mailbox) ->
        unless (account = _getByMailbox(mailbox.id)?.toJS())
            accountID = mailbox.accountID or _accounts?.first()?.get 'id'
            account = _accounts?.get(accountID)?.toJS()
            return unless account?
        account.mailboxes[mailbox.id] = mailbox
        _updateAccount account


    _updateAccount = (account) ->
        account = _toImmutable account
        _accounts = _accounts?.set account.get('id'), account



    ###
        Initialize private variables here.
    ###
    _initialize()


    ###
        Defines here the action handlers.
    ###
    __bindHandlers: (handle) ->


        handle ActionTypes.RESET_ACCOUNT_REQUEST, () ->
            _accounts = Immutable.OrderedMap()
            @emit 'change'


        handle ActionTypes.ADD_ACCOUNT_SUCCESS, ({account}) ->
            _updateAccount account
            @emit 'change'


        handle ActionTypes.RECEIVE_ACCOUNT_UPDATE, (account) ->
            _updateAccount account
            @emit 'change'


        handle ActionTypes.EDIT_ACCOUNT_SUCCESS, ({rawAccount}) ->
            _updateAccount rawAccount
            @emit 'change'


        handle ActionTypes.MAILBOX_DELETE_SUCCESS, (account) ->
            _updateAccount account
            @emit 'change'


        handle ActionTypes.REMOVE_ACCOUNT_SUCCESS, ({accountID}) ->
            _accounts = _accounts?.filter (account) ->
                account.get('id') isnt accountID
            @emit 'change'


        handle ActionTypes.MAILBOX_CREATE_SUCCESS, (mailbox) ->
            _updateMailbox mailbox
            @emit 'change'


        handle ActionTypes.RECEIVE_MAILBOX_CREATE, (mailbox) ->
            _updateMailbox mailbox
            @emit 'change'


        handle ActionTypes.MAILBOX_UPDATE_SUCCESS, (mailbox) ->
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


    getMailboxOrder: (accountID, mailboxID) ->
        if accountID and mailboxID
            return @getMailbox(accountID, mailboxID).get 'order'
        _mailboxOrder


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
            _accounts?.get(accountID).get 'mailboxes'


    isInbox: (accountID, mailboxID, getChildren=false) ->
        return false unless (mailbox = @getMailbox accountID, mailboxID)?.size

        account = @getByID(accountID)?.toObject()
        attribs = mailbox.get('attribs')
        attribs = unless getChildren then attribs?.join('/') else attribs?[0]

        isInbox = MailboxFlags.INBOX is attribs
        isInboxChild = unless getChildren then attribs?.length is 1 else true
        isGmailInbox = _isGmail(account) and isInboxChild

        return isInbox or isGmailInbox


    getInbox: (accountID) ->
        @getAllMailboxes(accountID)?.find (mailbox) =>
            @isInbox accountID, mailbox.get 'id'


    isTrashbox: (accountID, mailboxID) ->
        trashboxID = @getByID(accountID)?.get 'trashMailbox'
        trashboxID is mailboxID


    getAllMailbox: (accountID) ->
        @getAllMailboxes(accountID)?.find (mailbox) ->
            -1 < mailbox.get('attribs')?.indexOf MailboxFlags.ALL


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
