Process = require './_base'
OrphanRemoval = require './orphan_removal'
patchConversation = require '../patchs/conversation'
patchIgnored = require '../patchs/ignored'
log = require('../utils/logging')(prefix: 'process:application_startup')
Message = require '../models/message'
safeLoop = require '../utils/safeloop'
ramStore = require '../models/store_account_and_boxes'
cozydb = require 'cozydb'
async = require 'async'

module.exports = class ApplicationStartup extends Process

    code: 'application-startup'

    initialize: (options, callback) ->
        async.series [
            @forceCozyDBReindexing
            ramStore.initialize
            @initializeNewAccounts
            patchConversation.patchAllAccounts
            patchIgnored.patchAllAccounts
            @removeOrphans
        ], callback

    forceCozyDBReindexing: (callback) ->
        log.debug "cozydbReindexing"
        cozydb.forceReindexing callback

    initializeNewAccounts: (callback) ->
        log.debug "initializeNewAccounts"
        safeLoop ramStore.getUninitializedAccount(), (account, next) ->
            account.initialize next
        , (errors) ->
            log.error 'failed to init account', err for err in errors or []
            callback null

    removeOrphans: (callback) ->
        proc = new OrphanRemoval()
        proc.run callback
