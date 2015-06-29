if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"

casper.test.begin 'Test accounts with OAuth', (test) ->
    init casper

    casper.start casper.cozy.startUrl + '#account/gmail-ID/config/account', ->

    casper.then ->
        test.assertDoesntExist '#mailbox-password', 'Password field hidden'
        test.assertDoesntExist '.advanced-imap-toggle', 'Advanced IMAP parameters hidden'
        test.assertDoesntExist '.advanced-smtp-toggle', 'Advanced SMTP parameters hidden'
        casper.click 'button.action-save'
        casper.waitForSelector '.toast', ->
            test.assertEquals casper.fetchText('.toast .message').trim(), 'Account updated'
            casper.waitWhileSelector '.toast'

    casper.run ->
        test.done()

casper.test.begin 'Test accounts without OAuth', (test) ->
    init casper

    casper.start casper.cozy.startUrl + '#account/dovecot-ID/config/account', ->

    casper.then ->
        test.assertExist '#mailbox-password', 'Password field shown'
        test.assertExist '.advanced-imap-toggle', 'Advanced IMAP parameters shown'
        test.assertExist '.advanced-smtp-toggle', 'Advanced SMTP parameters shown'
        casper.click 'button.action-save'
        casper.waitForSelector '.toast', ->
            test.assertEquals casper.fetchText('.toast .message').trim(), 'Account updated'

    casper.run ->
        test.done()
