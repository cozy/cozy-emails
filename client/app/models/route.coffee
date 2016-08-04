Immutable = require('immutable')

exports.Filter = Filter = Immutable.Record
    sort: '-date'
    flags: null
    value: null
    before: null
    after: null
    pageAfter: null

Filter::toSimpleJS = ->
    @toMap().filter (value) -> value isnt null
            .toJS()

exports.Route = Immutable.Record
    URIKey: null
    action: null
    accountID: null
    mailboxID: null
    tab: null
    conversationID: null
    messageID: null
    messagesFilter: new exports.Filter()
