AccountStore = require '../stores/account_store'
MessageStore = require '../stores/message_store'

{MessageFlags, MailboxFlags} = require '../constants/app_constants'

_ = require 'lodash'

class MailboxesGetter

    getSelected: ->
        AccountStore.getSelectedMailboxes()

    getTags: (message) ->
        mailboxID = AccountStore.getSelectedMailbox()
        mailboxesIDs = Object.keys message.get 'mailboxIDs'
        result = mailboxesIDs.map (id) ->
            if (mailbox = AccountStore.getSelectedMailbox id)
                isGlobal = MailboxFlags.ALL in mailbox.get 'attribs'
                isEqual = mailboxID is id
                unless (isEqual or isGlobal)
                    return mailbox?.get 'label'
        _.uniq _.compact result

module.exports = new MailboxesGetter()
