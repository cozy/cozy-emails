require = patchRequire global.require
init    = require("../common").init
utils   = require "utils.js"
x       = require('casper.js').selectXPath

casper.test.begin 'Test Message Actions', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        casper.evaluate ->
            window.cozyMails.setSetting 'messagesPerPage', 100
            window.cozyMails.setSetting 'messageDisplayHTML', true
            window.cozyMails.setSetting 'messageDisplayImages', false
            window.cozyMails.setSetting 'displayConversation', true

    casper.then ->
        test.comment "Reply"
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Re: troll", "20141106093513.GH5642@mail.cozy.io", ->
            test.assertDoesntExist '#email-compose', "No compose form"
            casper.click '.messageToolbox button.reply'
            casper.waitForSelector '#email-compose', ->
                test.pass "Compose form displayed"
                test.assertNotVisible '#compose-cc', 'Cc hidden'
                test.assertNotVisible '#compose-bcc', 'Bcc hidden'
                values = casper.getFormValues('#email-compose form')
                test.assert values["compose-to"] is "you@cozycloud.cc", "Reply To"
                test.assert values["compose-cc"] is "", "Reply Cc"
                test.assert values["compose-bcc"] is "", "Reply Bcc"
                test.assert values["compose-subject"] is "Re: Re: troll", "Reply Subject"
                casper.click '.close-email'
                casper.waitWhileSelector '#email-compose', ->
                    test.pass "Compose closed"

    casper.then ->
        test.comment "Reply all"
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Re: troll", "20141106093513.GH5642@mail.cozy.io", ->
            test.assertDoesntExist '#email-compose', "No compose form"
            casper.click '.messageToolbox button.reply-all'
            casper.waitForSelector '#email-compose', ->
                test.pass "Compose form displayed"
                test.assertVisible '#compose-cc', 'Cc visible'
                test.assertNotVisible '#compose-bcc', 'Bcc hidden'
                values = casper.getFormValues('#email-compose form')
                test.assert values["compose-to"] is "you@cozycloud.cc", "Reply All To"
                test.assert values["compose-cc"] is '"Me" <me@cozycloud.cc>, "You" <you@cozycloud.cc>', "Reply All Cc"
                test.assert values["compose-bcc"] is "", "Reply All Bcc"
                test.assert values["compose-subject"] is "Re: Re: troll", "Reply Subject"

    casper.then ->
        test.comment "Forward"
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Re: troll", "20141106093513.GH5642@mail.cozy.io", ->
            test.assertDoesntExist '#email-compose', "No compose form"
            casper.click '.messageToolbox button.forward'
            casper.waitForSelector '#email-compose', ->
                test.pass "Compose form displayed"
                test.assertNotVisible '#compose-cc', 'Cc hidden'
                test.assertNotVisible '#compose-bcc', 'Bcc hidden'
                values = casper.getFormValues('#email-compose form')
                test.assert values["compose-to"] is "", "Forward To"
                test.assert values["compose-cc"] is "", "Forward Cc"
                test.assert values["compose-bcc"] is "", "Forward Bcc"
                test.assert values["compose-subject"] is "Fwd: Re: troll", "Reply Subject"


    casper.run ->
        test.done()
