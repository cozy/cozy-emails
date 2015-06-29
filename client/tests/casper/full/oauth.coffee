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
        # Ensure that no tast is displayed
        casper.waitWhileSelector '.toast'

    casper.then ->
        test.assertDoesntExist '#mailbox-password', 'Password field hidden'
        test.assertDoesntExist '#mailbox-imapServer', 'IMAP server hidden'
        test.assertDoesntExist '#mailbox-smtpServer', 'SMTP server hidden'
        casper.click 'button.action-save'
        casper.waitForSelector '.toast', ->
            test.assertEquals casper.fetchText('.toast .message').trim(), 'Account updated', 'Account update ok'
            casper.waitWhileSelector '.toast'

    casper.run ->
        test.done()

casper.test.begin 'Test accounts without OAuth', (test) ->
    init casper

    casper.start casper.cozy.startUrl + '#account/dovecot-ID/config/account', ->

    casper.then ->
        test.assertExist '#mailbox-password', 'Password field shown'
        test.assertExist '#mailbox-imapServer', 'IMAP server shown'
        test.assertExist '#mailbox-smtpServer', 'SMTP server shown'
        casper.click 'button.action-save'
        casper.waitForSelector '.toast', ->
            test.assertEquals casper.fetchText('.toast .message').trim(), 'Account updated', 'Account update ok'
            casper.waitWhileSelector '.toast'

    casper.run ->
        test.done()
