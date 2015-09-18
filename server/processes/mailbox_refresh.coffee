
Process = require './_base'
log = require('../utils/logging')(prefix: 'process/refreshpick')
ramStore = require '../models/store_account_and_boxes'
MailboxRefreshFast = require './mailbox_refresh_fast'
MailboxRefreshDeep = require './mailbox_refresh_deep'


module.exports = class MailboxRefresh extends Process

    code: 'mailbox-refresh'

    getProgress = =>
        @actualRefresh?.getProgress() or 0

    initialize: (options, callback) ->

        @mailbox = mailbox = options.mailbox
        account = ramStore.getAccount mailbox.accountID
        @shouldNotif = false
        return callback null unless account

        log.debug "refreshing box"
        if account.supportRFC4551 and mailbox.lastHighestModSeq
            @refreshFast (err) =>
                if err and err is MailboxRefreshFast.algorithmFailure
                    log.warn "refreshFast fail, trying deep"
                    @refreshDeep callback
                else if err
                    callback err
                else
                    callback null

        else
            if not account.supportRFC4551
                log.debug "account doesnt support RFC4551"
            else if not mailbox.lastHighestModSeq
                log.debug "no highestmodseq, first refresh ?"
                @options.storeHighestModSeq = true

            @refreshDeep callback


    refreshFast: (callback) =>
        @actualRefresh = new MailboxRefreshFast @options
        @actualRefresh.run (err) =>
            @shouldNotif = @actualRefresh.shouldNotif
            callback err

    refreshDeep: (callback) =>
        @actualRefresh = new MailboxRefreshDeep @options
        @actualRefresh.run (err) =>
            @shouldNotif = @actualRefresh.shouldNotif
            callback err
