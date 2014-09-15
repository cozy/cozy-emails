americano = require 'americano-cozy'
module.exports = Message = americano.getModel 'Message',
    account: String
    mailboxIDs: (x) -> x
    subject: String
    from: (x) -> x
    to: (x) -> x
    cc: (x) -> x
    replyTo: (x) -> x
    text: String
    html: String
    date: Date
    inReplyTo: String
    references: String
    createdAt: Date
    priority: String
    headers: (x) -> x

Message.getByMailboxAndDate = (mailboxID, callback) ->
    options =
        startkey: [mailboxID, {}]
        endkey: [mailboxID]
        include_docs: true
        descending: true
    Message.rawRequest 'byMailboxAndDate', options, (err, results) ->
        return callback err if err
        callback null, results.map (item) -> new Message(item.doc)

Message.destroyByMailbox = (mailboxID, callback) ->
    Message.requestDestroy 'byMailbox', key: mailboxID, callback

require('bluebird').promisifyAll Message, suffix: 'Promised'
require('bluebird').promisifyAll Message::, suffix: 'Promised'

# attributes =
#     mailbox: String
#     folder: String
#     idRemoteEmailbox: String # ?
#     remoteUID: String # ?
#     createdAt: type: Number, default: 0
#     dateValueOf: type: Number, default: 0 # ?
#     date: type: Date, default: 0 # ?
#     headersRaw: String # ?
#     raw: String # ?
#     priority: String # ?

#     subject: String
#     from: String
#     to: String
#     cc: String
#     bcc: String
#     references: String
#     inReplyTo: String
#     text: String
#     html: String

#     flags: Object # ?
#     read: type: Boolean, default: false
#     flagged: type: Boolean, default: false # ?
#     hasAttachments: type: Boolean, default: false
#     _attachments: Object
