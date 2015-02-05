require = patchRequire global.require
init    = require("../common").init
utils   = require "utils.js"

casper.test.begin 'Test draft', (test) ->
    init casper

    casper.start casper.cozy.startUrl + "#compose", ->
        test.comment "Compose Draft"
        casper.evaluate ->
            window.cozyMails.setSetting 'composeInHTML', true
        casper.click '.form-compose [data-value=dovecot-ID]'
        casper.click '.form-compose .compose-toggle-cc'
        casper.click '.form-compose .compose-toggle-bcc'
        casper.fillSelectors 'form',
            "#compose-bcc": "bcc@cozy.io",
            "#compose-cc": "cc@cozy.io",
            "#compose-subject": "my draft subject",
            "#compose-to": "to@cozy.io"
        casper.evaluate ->
            document.querySelector('.rt-editor').innerHTML = "<p><em>Hello,</em><br>Join us now and share the software</p>"
        casper.sendKeys '.rt-editor', "\n"
        casper.click '.composeToolbox .btn-save'
        casper.waitForSelector '.composeToolbox .fa-refresh', ->
            casper.waitWhileSelector '.composeToolbox .fa-refresh', ->
                test.pass 'Message should be saved'
                casper.reload

    casper.then ->
        test.comment "Edit draft"
        casper.cozy.selectMessage "DoveCot", "Draft", "my draft subject", (messageID) ->
            console.log messageID
            test.assertExists '#email-compose', 'Compose form is displayed'
            values = casper.getFormValues('#email-compose form')
            test.assertEquals values["compose-bcc"], "bcc@cozy.io"
            test.assertEquals values["compose-cc"], "cc@cozy.io"
            test.assertEquals values["compose-subject"], "my draft subject"
            test.assertEquals values["compose-to"], "to@cozy.io"
            test.assertEquals casper.fetchText('.rt-editor'), "Hello,Join us now and share the software", "message HTML"
            message = casper.evaluate ->
                return window.cozyMails.getCurrentMessage()
            test.assertEquals message.text, "_\n_\n\n_Hello,_\nJoin us now and share the software", "messageText"
            casper.click '.composeToolbox .btn-delete'
            casper.waitWhileSelector '#email-compose', ->
                test.pass 'Compose closed'
                casper.reload ->
                    test.assertDoesntExist "li.message[data-message-id='#{messageID}']", "message deleted"



    casper.run ->
        test.done()
