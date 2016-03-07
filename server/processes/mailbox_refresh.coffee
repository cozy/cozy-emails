
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

        return callback null if "\\Noselect" in mailbox.attribs

        log.debug "refreshing box"
        fastSupport = account.supportRFC4551 and mailbox.lastHighestModSeq
        if fastSupport and not options.deep
            @refreshFast (err) =>
                if err and err is MailboxRefreshFast.algorithmFailure or
                err is MailboxRefreshFast.tooManyMessages
                    log.warn "refreshFast fail #{err.Symbol}, trying deep"
                    @options.storeHighestModSeq = true
                    @refreshDeep callback
                else if err
                    callback err
                else
                    callback null

        else
            if options.deep
                log.debug "force deep refresh"
            else if not account.supportRFC4551
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
