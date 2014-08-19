americano = require 'americano-cozy'
module.exports = Email = americano.getModel 'Email',
    mailbox: String
    subject: String
    from: String
    to: String
    text: String
    date: Date
    inReplyTo: String
    createdAt: Date
    imapFolder: String

Email.getByMailboxAndDate = (mailboxID, callback) ->
    options =
        startkey: [mailboxID, {}]
        endkey: [mailboxID]
        descending: true
    Email.request 'byMailboxAndDate', options, callback

Email.destroyByMailbox = (mailboxID, callback) ->
    Email.requestDestroy 'byMailbox', key: mailboxID, callback

attributes =
    mailbox: String
    folder: String
    idRemoteEmailbox: String # ?
    remoteUID: String # ?
    createdAt: type: Number, default: 0
    dateValueOf: type: Number, default: 0 # ?
    date: type: Date, default: 0 # ?
    headersRaw: String # ?
    raw: String # ?
    priority: String # ?

    subject: String
    from: String
    to: String
    cc: String
    bcc: String
    references: String
    inReplyTo: String
    text: String
    html: String

    flags: Object # ?
    read: type: Boolean, default: false
    flagged: type: Boolean, default: false # ?
    hasAttachments: type: Boolean, default: false
    _attachments: Object
