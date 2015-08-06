Process = require './_base'

INRAM = 10000

module.exports = class MailboxRefreshSeq extends Process


    initialize: (options, callback) ->
        @mailbox = options.mailbox

        @currentMinSeq = 0
        @maxSeq = 1






    fetchImapUIDS: (callback) ->
        @mailbox.doASAPWithBox



