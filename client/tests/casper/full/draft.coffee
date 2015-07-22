if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"

initSettings = ->
    casper.evaluate ->
        settings =
            "composeInHTML": true
            "composeOnTop": false
            "displayConversation": true
            "displayPreview":true
            "layoutStyle":"three"
            "messageConfirmDelete":false
        window.cozyMails.setSetting settings

casper.test.begin 'Test draft', (test) ->
    init casper

    messageID = ''
    messageSubject = "My draft subject #{new Date().toUTCString()}"

    casper.start casper.cozy.startUrl, ->
        test.comment "Compose Draft"
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    casper.then ->
        test.comment "Compose Account"
        casper.click ".compose-action"
        casper.waitForSelector ".form-compose .rt-editor", ->
            casper.waitWhileSelector '.composeToolbox .button-spinner', ->
                if casper.exists '.compose-from [data-value="dovecot-ID"]'
                    test.assertEquals casper.fetchText('.account-picker .compose-from').trim(), 'DoveCot <me@cozytest.cc>', 'Account selected'
                else
                    casper.click '.account-picker .caret'
                    casper.waitUntilVisible '.account-picker .dropdown-menu', ->
                        test.pass 'Account picker displayed'
                        casper.click '.account-picker .dropdown-menu [data-value="dovecot-ID"]', ->
                        casper.waitForSelector '.compose-from [data-value="dovecot-ID"]', ->
                            test.assertEquals casper.fetchText('.account-picker .compose-from').trim(), 'DoveCot <me@cozytest.cc>', 'Account selected'

    casper.then ->
        test.comment "Compose message"
        casper.click '.form-compose .compose-toggle-cc'
        casper.click '.form-compose .compose-toggle-bcc'
        casper.fillSelectors 'form',
            "#compose-subject": messageSubject,
        casper.sendKeys "#compose-bcc", "bcc@cozy.io,",
        casper.sendKeys "#compose-cc", "cc@cozy.io,",
        casper.sendKeys "#compose-to", "to@cozy.io,"
        casper.evaluate ->
            editor = document.querySelector('.rt-editor')
            editor.innerHTML = "<div><em>Hello,</em><br>Join us now and share the software</div>"
            evt = document.createEvent 'HTMLEvents'
            evt.initEvent 'input', true, true
            editor.dispatchEvent evt
        casper.click '.composeToolbox .btn-save'
        casper.waitForSelector '.composeToolbox .button-spinner', ->
            casper.waitWhileSelector '.composeToolbox .button-spinner', ->
                message = casper.evaluate ->
                    window.cozyMails.getCurrentMessage()
                messageID = message.id
                test.pass "Message '#{message.subject}' is saved: #{messageID}"

    casper.then ->
        test.comment "Leave compose"
        #initSettings()
        casper.cozy.selectAccount "DoveCot", 'Draft', ->
            casper.waitUntilVisible '.modal-dialog',  ->
                confirm = casper.fetchText('.modal-body').trim()
                test.assertEquals confirm, "Message not sent, keep the draft?", "Confirmation dialog"
                casper.click ".modal-dialog .btn.modal-close"
                casper.waitWhileVisible '.modal-dialog'

    casper.then ->
        test.comment "Edit draft"
        #initSettings()
        casper.cozy.selectMessage "DoveCot", "Draft", messageSubject, messageID, ->
            casper.waitForSelector ".form-compose .rt-editor", ->
                test.assertExists '.form-compose', 'Compose form is displayed'
                values = casper.getFormValues('.form-compose')
                test.assertEquals casper.fetchText(".compose-bcc .address-tag"), "bcc@cozy.io", "Bcc dests"
                test.assertEquals casper.fetchText(".compose-cc .address-tag"), "cc@cozy.io", "Cc dests"
                test.assertEquals casper.fetchText(".compose-to .address-tag"), "to@cozy.io", "To dests"
                test.assertEquals values["compose-subject"], messageSubject, "Subject"
                test.assertEquals casper.fetchText('.rt-editor'), "\nHello,Join us now and share the software", "message HTML"
                message = casper.evaluate ->
                    return window.cozyMails.getCurrentMessage()
                test.assertEquals message.text, "_Hello,_\nJoin us now and share the software", "messageText"
                casper.click '.composeToolbox .btn-delete'
                casper.waitUntilVisible '.modal-dialog',  ->
                    confirm = casper.fetchText('.modal-body').trim()
                    test.assertEquals confirm, "Do you really want to delete message “#{messageSubject}”?", "Confirmation dialog"
                    casper.click ".modal-dialog .btn.modal-action"
                    casper.waitWhileSelector ".form-compose h3[data-message-id=#{messageID}]", ->
                        test.pass 'Compose closed'
                        if casper.getEngine() is 'slimer'
                            # delete doesn't work in PhantomJs
                            casper.waitWhileSelector "li.message[data-message-id='#{messageID}']", ->
                                test.pass "message deleted"
                                casper.reload ->
                                    test.assertDoesntExist "li.message[data-message-id='#{messageID}']", "message really deleted"

    casper.run ->
        test.done()
