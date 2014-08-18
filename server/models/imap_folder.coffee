#americano = require 'americano-cozy'

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
