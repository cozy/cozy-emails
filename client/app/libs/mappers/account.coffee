Immutable = require 'immutable'
_ = require 'lodash'

{ActionTypes, MailboxFlags, MailboxSpecial} = require '../../constants/app_constants'

module.exports =

    # FIXME: all this stuff should be done sever side
    # its only about fixing what server side part doesnt complete
    formatMailbox: (account, mailbox) ->
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

        if @isGmail(account)
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
        mailbox.order = @getMailboxOrder mailbox, 100

        return mailbox

    formatAccount: (rawAccount) ->
        account = _.cloneDeep rawAccount
        _mailboxes = _.compact _.map account.mailboxes, (mailbox) =>
                @formatMailbox account, mailbox
            .filter (mailbox) =>
                @filterDuplicateMailbox rawAccount, mailbox if mailbox

        account.mailboxes = Immutable.Iterable _mailboxes
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

            .map (mailbox) -> Immutable.Map mailbox
            .toOrderedMap()

        return Immutable.Map account


    filterDuplicateMailbox: (account, mailbox) ->
        # OVH issue
        # mailboxes has 2 mailbox called INBOX
        # but only one the the real one
        # remove the fake one
        # TODO: should be done server side
        if _.isEqual mailbox.attribs, [MailboxFlags.INBOX]
            return mailbox.id is account.inboxMailbox
        else
            return true


     # Temporary code duplication, should be in an util/service library
    isGmail: (account) ->
        -1 < account.label?.toLowerCase().indexOf 'gmail'



    # Get Mailbox Sort Order
    # These special mailbox should always appears on top
    # in the same order
    getMailboxOrder: ({attribs, tree, label, attrib}, defaultOrder=100) ->
        if attribs?.length
            value = _.reduce attribs, (result, attrib) =>
                result.push index if -1 < (index = @getMailboxOrder {attrib})
                result
            , []
            if (index = value.shift())?
                index = "#{index}.#{decimal}" if (decimal = value.join '').length
                return index * 1

        else if attrib?
            index = _.findIndex _.keys(MailboxFlags), (key) -> MailboxFlags[key] is attrib
            return index if -1 < index

        return defaultOrder
