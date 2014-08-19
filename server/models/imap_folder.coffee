americano = require 'americano-cozy'

module.exports = ImapFolder = americano.getModel 'ImapFolder',
    name: String
    path: String
    mailbox: String


ImapFolder.getByMailbox = (mailboxID, callback) ->
    ImapFolder.request 'byMailbox', key: mailboxID, callback

# MailFolder is a IMAP Mailbox, it contains mails.
#module.exports = MailFolder = americano.getModel 'MailFolder',
attributes =
    id: String
    name: String
    path: String # ?
    specialType: String # ?
    imapLastFetchedId: type: Number, default: 0
    mailsToBe: Object # ?
    mailbox: String
