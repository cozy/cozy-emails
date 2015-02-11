if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"
x     = require('casper.js').selectXPath

casper.test.begin 'Test Message Actions', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        casper.evaluate ->
            window.cozyMails.setSetting 'messageDisplayHTML', true
            window.cozyMails.setSetting 'messageDisplayImages', false
            window.cozyMails.setSetting 'displayConversation', false
            window.cozyMails.setSetting 'displayPreview', true
            window.cozyMails.setSetting 'messageConfirmDelete', true
            window.cozyMails.setSetting 'composeInHTML', true

    casper.then ->
        test.comment "Reply"
        messageID = "20141106093513.GH5642@mail.cozy.io"
        currentSel = ".conversation li.message.active[data-id='#{messageID}']"
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Re: troll", messageID, ->
            test.assertEquals casper.fetchText("#{currentSel} .participants"), 'contact, Me, You', 'Participants list'
            test.assertDoesntExist "#{currentSel} #email-compose", "No compose form"
            casper.click "#{currentSel} .messageToolbox button.reply"
            casper.waitForSelector '#email-compose', ->
                test.pass "Compose form displayed"
                test.assertNotVisible '.form-group.compose-cc', 'Cc hidden'
                test.assertNotVisible '.form-group.compose-bcc', 'Bcc hidden'
                values = casper.getFormValues('#email-compose form')
                test.assertEquals values["compose-to"], "you@cozycloud.cc", "Reply To"
                test.assertEquals values["compose-cc"], "", "Reply Cc"
                test.assertEquals values["compose-bcc"], "", "Reply Bcc"
                test.assertEquals values["compose-subject"], "Re: Re: troll", "Reply Subject"
                casper.sendKeys '.rt-editor', 'Toto', keepFocus: true
                text = casper.fetchText '.rt-editor'
                test.assertEquals text.substr(-4), 'Toto', "Compose under original message"
                casper.click '.form-compose .btn-cancel'
                casper.waitWhileSelector '#email-compose', ->
                    test.pass "Compose closed"

    casper.then ->
        test.comment "Compose on top"
        casper.evaluate ->
            window.cozyMails.setSetting 'composeOnTop', true
            window.cozyMails.setSetting 'composeInHTML', true
        messageID =  "20141106093513.GH5642@mail.cozy.io"
        currentSel = ".conversation li.message.active[data-id='#{messageID}']"
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Re: troll", messageID, ->
            casper.click "#{currentSel} .messageToolbox button.reply"
            casper.waitForSelector '.rt-editor', ->
                casper.sendKeys '.rt-editor', 'Toto', keepFocus: true
                text = casper.fetchText '.rt-editor'
                test.assertEquals text.substr(0, 4), 'Toto', "Compose on top"
                test.assertExists '.rt-editor.folded', 'Original mail is hidden'
                casper.click '.rt-editor .originalToggle'
                casper.waitWhileSelector '.rt-editor.folded', ->
                    test.pass 'Original mail is shown'
                    casper.click '.form-compose .btn-cancel'
                    casper.waitWhileSelector '#email-compose', ->
                        casper.evaluate ->
                            window.cozyMails.setSetting 'composeOnTop', false

    casper.then ->
        test.comment "Reply all"
        messageID =  "20141106093513.GH5642@mail.cozy.io"
        currentSel = ".conversation li.message.active[data-id='#{messageID}']"
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Re: troll", messageID, ->
            test.assertEquals casper.fetchText("#{currentSel} .participants"), 'contact, Me, You', 'Participants'
            test.assertDoesntExist '#email-compose', "No compose form"
            casper.click "#{currentSel} .messageToolbox button.reply-all"
            casper.waitForSelector '#email-compose', ->
                test.pass "Compose form displayed"
                test.assertVisible '.form-group.compose-cc', 'Cc shown'
                test.assertNotVisible '.form-group.compose-bcc', 'Bcc hidden'
                values = casper.getFormValues('#email-compose form')
                test.assertEquals values["compose-to"], "you@cozycloud.cc", "Reply All To"
                test.assertEquals values["compose-cc"], 'contact@cozycloud.cc', "Reply All Cc"
                test.assertEquals values["compose-bcc"], "", "Reply All Bcc"
                test.assertEquals values["compose-subject"], "Re: Re: troll", "Reply Subject"
                casper.click '.form-compose .btn-cancel'
                casper.waitWhileSelector '#email-compose'

    casper.then ->
        test.comment "Forward"
        messageID =  "20141106093513.GH5642@mail.cozy.io"
        currentSel = ".conversation li.message.active[data-id='#{messageID}']"
        casper.cozy.selectMessage "DoveCot", "Test Folder", "Re: troll", messageID, ->
            test.assertDoesntExist '#email-compose', "No compose form"
            casper.click "#{currentSel} .messageToolbox button.forward"
            casper.waitForSelector '#email-compose', ->
                test.pass "Compose form displayed"
                test.assertNotVisible '.form-group.compose-cc', 'Cc hidden'
                test.assertNotVisible '.form-group.compose-bcc', 'Bcc hidden'
                values = casper.getFormValues('#email-compose form')
                test.assertEquals values["compose-to"], "", "Forward To"
                test.assertEquals values["compose-cc"], "", "Forward Cc"
                test.assertEquals values["compose-bcc"], "", "Forward Bcc"
                test.assertEquals values["compose-subject"], "Fwd: Re: troll", "Reply Subject"
                casper.click '.form-compose .btn-cancel'
                casper.waitWhileSelector '#email-compose'

    ###
    # Commenting this out, as support of HTTP PATCH Verb is very buggy in PhantomJS
    #
    casper.then ->
        test.comment "Delete"
        confirm = ''
        casper.evaluate ->
            window.cozytest = {}
            window.cozytest.confirm = window.confirm
            window.confirm = (txt) ->
                console.log txt
                window.cozytest.confirmTxt = txt
                return true
        casper.evaluate ->
            window.cozyMails.setSetting 'messageDisplayHTML', true
            window.cozyMails.setSetting 'messageDisplayImages', false
            window.cozyMails.setSetting 'displayConversation', false
            window.cozyMails.setSetting 'displayPreview', true
            window.cozyMails.setSetting 'messageConfirmDelete', false
            window.cozyMails.setSetting 'composeInHTML', true
        casper.cozy.selectMessage "DoveCot", "Test Folder", null, (subject, messageID) ->
            currentSel = ".conversation li.message.active[data-id='#{messageID}']"
            console.log "#{currentSel} .messageToolbox button.trash"
            casper.click "#{currentSel} .messageToolbox button.trash"
            casper.waitWhileSelector ".message-list li.message[data-message-id='#{messageID}']", ->
                test.pass "Message #{subject} Moved"
                casper.cozy.selectMessage "DoveCot", "Trash", subject, messageID, ->
                    test.pass 'Message is in Trash'
                    casper.click "#{currentSel} .messageToolbox button.move"
                    boxSelector = "#{currentSel} .messageToolbox [data-value='dovecot-ID-folder1']"
                    casper.waitUntilVisible boxSelector, ->
                        test.pass 'Move menu displayed'
                        casper.click boxSelector
                        casper.waitWhileSelector ".message-list li.message[data-message-id='#{messageID}']", ->
                            casper.cozy.selectMessage "DoveCot", "Test Folder", subject, messageID, ->
                                test.pass "Message moved back to original folder"
    ###

    casper.run ->
        test.done()
