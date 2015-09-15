if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"
x     = require('casper.js').selectXPath

selectInConv = (account, folder, subject, messageID, cb) ->
    casper.cozy.selectMessage account, folder, subject, null, ->
        sel = ".conversation article.message.active[data-id='#{messageID}']"
        if casper.exists sel
            cb()
        else
            if casper.exists ".conversation .more"
                casper.click ".conversation .more"
            casper.waitWhileSelector ".conversation .more", ->
                casper.click ".conversation article.message[data-id='#{messageID}'] header"
                casper.waitForSelector sel, cb

casper.test.begin 'Test Message Actions', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    # casper.then ->
    #     test.comment "Reply"
    #     messageID = "20141106093513.GH5642@mail.cozy.io"
    #     currentSel = ".conversation article.message.active[data-id='#{messageID}']"
    #     selectInConv "DoveCot", "Test Folder", "Re: troll", messageID, ->
    #         test.assertEquals casper.fetchText("#{currentSel} .infos .from"), 'contact@cozytest.cc', 'From'
    #         test.assertEquals casper.fetchText("#{currentSel} .infos .to .participant"), "Meme@cozytest.cc", 'To'
    #         test.assertEquals casper.fetchText("#{currentSel} .infos .cc .participant"), "Youyou@cozytest.cc", 'Cc'
    #         test.assertDoesntExist "#{currentSel} .form-compose", "No compose form"
    #         casper.click "#{currentSel} header .toolbar-message button.mail-reply"
    #         casper.waitForSelector '.form-compose', ->
    #             test.pass "Compose form displayed"
    #             test.assertNotVisible '.form-group.compose-cc', 'Cc hidden'
    #             test.assertNotVisible '.form-group.compose-bcc', 'Bcc hidden'
    #             values = casper.getFormValues('.form-compose')
    #             test.assertEquals casper.fetchText(".compose-to .address-tag"), "you@cozytest.cc", "Reply To"
    #             test.assertEquals casper.fetchText(".compose-cc .address-tag"), "", "Reply Cc"
    #             test.assertEquals casper.fetchText(".compose-bcc .address-tag"), "", "Reply Bcc"
    #             test.assertEquals values["compose-subject"], "Re: troll", "Reply Subject"
    #             casper.sendKeys '.rt-editor', 'Toto', keepFocus: true
    #             text = casper.fetchText '.rt-editor'
    #             test.assertEquals text.substr(-4), 'Toto', "Compose under original message"
    #             casper.click '.form-compose .btn-cancel'
    #             casper.waitWhileSelector '.form-compose', ->
    #                 test.pass "Compose closed"
    #                 casper.wait 2000

    #casper.then ->
    #    test.comment "Compose on top"
    #    #casper.evaluate ->
    #    #    window.cozyMails.setSetting 'composeOnTop', true
    #    #    window.cozyMails.setSetting 'composeInHTML', true
    #    messageID =  "20141106093513.GH5642@mail.cozy.io"
    #    currentSel = ".conversation article.message.active[data-id='#{messageID}']"
    #    selectInConv "DoveCot", "Test Folder", "Re: troll", messageID, ->
    #        casper.click "#{currentSel} header .toolbar-message button.mail-reply"
    #        casper.waitForSelector '.rt-editor', ->
    #            casper.sendKeys '.rt-editor', 'Toto', keepFocus: true
    #            text = casper.fetchText '.rt-editor'
    #            test.assertEquals text.substr(0, 4), 'Toto', "Compose on top"
    #            test.assertExists '.rt-editor.folded', 'Original mail is hidden'
    #            casper.click '.rt-editor .originalToggle'
    #            casper.waitWhileSelector '.rt-editor.folded', ->
    #                test.pass 'Original mail is shown'
    #                casper.click '.form-compose .btn-cancel'
    #                casper.waitWhileSelector '.form-compose', ->
    #                    casper.evaluate ->
    #                        window.cozyMails.setSetting 'composeOnTop', false

    # casper.then ->
    #     test.comment "Reply all"
    #     messageID =  "20141106093513.GH5642@mail.cozy.io"
    #     currentSel = ".conversation article.message.active[data-id='#{messageID}']"
    #     selectInConv "DoveCot", "Test Folder", "Re: troll", messageID, ->
    #         test.assertDoesntExist '.form-compose', "No compose form"
    #         casper.click "#{currentSel} header .toolbar-message button.mail-reply-all"
    #         casper.waitForSelector '.form-compose', ->
    #             test.pass "Compose form displayed"
    #             test.assertVisible '.form-group.compose-cc', 'Cc shown'
    #             test.assertNotVisible '.form-group.compose-bcc', 'Bcc hidden'
    #             values = casper.getFormValues('.form-compose')
    #             test.assertEquals casper.fetchText(".compose-to .address-tag"), "you@cozytest.cc", "Reply All To"
    #             test.assertEquals casper.fetchText(".compose-cc .address-tag"), 'contact@cozytest.cc', "Reply All Cc"
    #             test.assertEquals casper.fetchText("compose-bcc .address-tag"), "", "Reply All Bcc"
    #             test.assertEquals values["compose-subject"], "Re: troll", "Reply Subject"
    #             casper.click '.form-compose .btn-cancel'
    #             casper.waitWhileSelector '.form-compose', ->
    #                 casper.wait 2000

    # casper.then ->
    #     test.comment "Forward"
    #     messageID =  "20141106093513.GH5642@mail.cozy.io"
    #     currentSel = ".conversation article.message.active[data-id='#{messageID}']"
    #     selectInConv "DoveCot", "Test Folder", "Re: troll", messageID, ->
    #         test.assertDoesntExist '.form-compose', "No compose form"
    #         casper.click "#{currentSel} header .toolbar-message button.mail-forward"
    #         casper.waitForSelector '.form-compose', ->
    #             test.pass "Compose form displayed"
    #             test.assertNotVisible '.form-group.compose-cc', 'Cc hidden'
    #             test.assertNotVisible '.form-group.compose-bcc', 'Bcc hidden'
    #             values = casper.getFormValues('.form-compose')
    #             test.assertEquals casper.fetchText(".compose-to .address-tag"), "", "Forward To"
    #             test.assertEquals casper.fetchText(".compose-cc .address-tag"), "", "Forward Cc"
    #             test.assertEquals casper.fetchText(".compose-bcc .address-tag"), "", "Forward Bcc"
    #             test.assertEquals values["compose-subject"], "Fwd: Re: troll", "Reply Subject"
    #             casper.click '.form-compose .btn-cancel'
    #             casper.waitWhileSelector '.form-compose', ->
    #                 casper.wait 2000

    casper.then ->
        if casper.getEngine() isnt 'slimer'
            test.comment "Skipping, as PhantomJS doesn't support PATCH verb"
            test.assert true
            test.skip 1
        else
            test.comment "Delete"
            casper.cozy.selectMessage "DoveCot", "Test Folder", null, (subject, messageID) ->
                selectInConv "DoveCot", "Test Folder", subject, messageID, ->
                    currentSel = ".conversation article.message.active[data-id='#{messageID}']"
                    casper.click "#{currentSel} header .toolbar-message button.fa-trash"
                    casper.waitUntilVisible '.modal-dialog',  ->
                        confirm = casper.fetchText('.modal-body').trim()
                        test.assertEquals confirm, "Do you really want to delete message “Re: Conversation”?", "Confirmation dialog"
                        casper.click ".modal-dialog .btn:not(.btn-cozy-non-default)"
                        casper.waitWhileSelector ".messages-list article.message[data-message-id='#{messageID}']", ->
                            test.pass "Message #{subject} Moved"
                            selectInConv "DoveCot", "Trash", subject, messageID, ->
                                test.pass 'Message is in Trash'
                                casper.click "#{currentSel} header .toolbar-message button.fa-folder-open"
                                boxSelector = "#{currentSel} header .toolbar-message [data-value='f5cbd722-c3f9-4f6e-73d0-c75ddf65a2f1']"
                                casper.waitUntilVisible boxSelector, ->
                                    test.pass 'Move menu displayed'
                                    casper.click boxSelector
                                    casper.waitWhileSelector ".messages-list article.message[data-message-id='#{messageID}']", ->
                                        casper.cozy.selectMessage "DoveCot", "Test Folder", subject, messageID, ->
                                            test.pass "Message moved back to original folder"

    casper.run ->
        test.done()
