NotificationsHelper = require 'cozy-notifications-helper'
notificationsHelper = new NotificationsHelper 'emails'
localization = require './localization'
SocketHandler = require './socket_handler'
log = require('./logging')(prefix: 'notifications')

emailsAppRessource = app: 'emails', url: '/'
logError = (err) ->
    log.error "fail to create notif", err if err

exports.accountFirstImportComplete = (account) ->
    localization.getPolyglot (err, t) ->

        text = t 'notif complete',
            account: account.label

        notificationsHelper.createTemporary
            resource: emailsAppRessource
            text: text
        , logError

exports.accountRefreshed = (account) ->
    localization.getPolyglot (err, t) ->
        account.totalUnread (err, totalUnread) ->
            ref = "notif-unread-#{account.id}"
            if totalUnread is 0
                notificationsHelper.destroy ref
            else
                message = t 'notif new',
                    smart_count: totalUnread
                    account: account.label

                accountID = account.id

                data = {message, totalUnread, accountID}

                SocketHandler.notify 'refresh.notify', data, logError

                notificationsHelper.createOrUpdatePersistent ref,
                    resource:
                        app: 'emails',
                        url: "/#account/#{accountID}"
                    text: message
                , logError
