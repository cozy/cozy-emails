Process = require './_base'
OrphanRemoval = require './orphan_removal'
patchIgnored = require '../patchs/ignored'
log = require('../utils/logging')(prefix: 'process:application_startup')
ramStore = require '../models/store_account_and_boxes'
Message = require '../models/message'
Mailbox = require '../models/mailbox'
safeLoop = require '../utils/safeloop'
cozydb = require 'cozydb'
async = require 'async'
MailboxRefreshList = require '../processes/mailbox_refresh_list'


module.exports = class ApplicationStartup extends Process

    code: 'application-startup'

    initialize: (options, callback) ->
        async.series [
            @forceCozyDBReindexing
            ramStore.initialize
            @initializeNewAccounts
            patchIgnored.patchAllAccounts
            @removeOrphans
        ], callback

    forceCozyDBReindexing: (callback) ->
        log.debug "cozydbReindexing"
        cozydb.forceReindexing callback

    initializeNewAccounts: (callback) ->
        log.debug "initializeNewAccounts"
        safeLoop ramStore.getUninitializedAccount(), (account, next) ->
            refreshList = new MailboxRefreshList {account}
            refreshList.run (err) =>
                return next err if err
                boxes = ramStore.getMailboxesByAccount @id
                changes = Mailbox.scanBoxesForSpecialUse boxes
                changes.initialized = true
                account.updateAttributes changes, next
        , (errors) ->
            log.error 'failed to init account', err for err in errors or []
            callback null

    removeOrphans: (callback) ->
        proc = new OrphanRemoval()
        proc.run callback
