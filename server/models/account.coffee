americano = require 'americano-cozy'
module.exports = Account = americano.getModel 'Account',
    label: String
    login: String
    password: String
    smtpServer: String
    smtpPort: Number
    imapServer: String
    imapPort: Number
    mailboxes: (x) -> x

Account.getAll = (callback) -> Account.request 'all', callback

Account.pathOfId = (id, callback) ->
    Account.rawRequest 'pathById', key: id, (err, results) ->
        callback err, results?.rows[0]?.value

Account::mailboxIds = (callback) ->
    ids = []
    do getIDs = (children = @mailboxes) ->
        for child in children
            ids.push child.id
            getIDs child.children
    return ids


require('bluebird').promisifyAll Account, suffix: 'Promised'
require('bluebird').promisifyAll Account::, suffix: 'Promised'
# attributes =

#     # identification
#     name: String
#     config: type: Number, default: 0
#     newMessages: type: Number, default: 0
#     createdAt: type: Date, default: Date

#     # shared credentails for in and out bound
#     login: String
#     password: String

#     # data for outbound mails - SMTP
#     smtpServer: String
#     smtpSendAs: String
#     smtpSsl: type: Boolean, default: true
#     smtpPort: type: Number, default: 465

#     # data for inbound mails - IMAP
#     imapServer: String
#     imapPort: String
#     imapSecure: type: Boolean, default: true
#     imapLastSync: type: Date, default: 0
#     imapLastFetchedDate: type: Date, default: 0
#     # this one is used to build the query to fetch new mails
#     imapLastFetchedId: type: Number, default: 0

#     # data regarding the interface
#     checked: type: Boolean, default: true
#     # color of the mailbox in the list
#     color: type: String, default: "#0099FF"
#     # status visible for user
#     statusMsg: type: String, default: "Waiting for import"

#     # data for import
#     # ready to be fetched for new mail
#     activated: type: Boolean, default: false
#     status: type: String, default: "freezed"
#     mailsToImport: type: Number, default: 0
