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
        casper.click ".compose-action"
        casper.waitForSelector ".form-compose .rt-editor", ->
            casper.waitWhileSelector '.composeToolbox .button-spinner', ->
                casper.click '.form-compose [data-value=dovecot-ID]'
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
                    casper.click ".modal-dialog .btn:not(.btn-cozy-non-default)"
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
