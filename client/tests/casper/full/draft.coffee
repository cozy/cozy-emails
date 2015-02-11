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
            "displayConversation":false
            "displayPreview":true
            "layoutStyle":"three"
            "listStyle":"compact"
            "messageConfirmDelete":false
        window.cozyMails.setSetting settings

casper.test.begin 'Test draft', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        test.comment "Compose Draft"
        initSettings()
        casper.waitFor ->
            casper.evaluate ->
                window.cozyMails.getSetting 'composeInHTML'

    casper.then ->
        casper.click "#menu .compose-action"
        casper.waitForSelector "#email-compose .rt-editor", ->
            casper.click '.form-compose [data-value=dovecot-ID]'
            casper.click '.form-compose .compose-toggle-cc'
            casper.click '.form-compose .compose-toggle-bcc'
            casper.fillSelectors 'form',
                "#compose-bcc": "bcc@cozy.io",
                "#compose-cc": "cc@cozy.io",
                "#compose-subject": "my draft subject",
                "#compose-to": "to@cozy.io"
            casper.evaluate ->
                editor = document.querySelector('.rt-editor')
                editor.innerHTML = "<div><em>Hello,</em><br>Join us now and share the software</div>"
                evt = document.createEvent 'HTMLEvents'
                evt.initEvent 'input', true, true
                editor.dispatchEvent evt
            casper.click '.composeToolbox .btn-save'
            casper.waitForSelector '.composeToolbox .fa-refresh', ->
                casper.waitWhileSelector '.composeToolbox .fa-refresh', ->
                    test.pass 'Message should be saved'
                    #casper.reload

    casper.then ->
        test.comment "Edit draft"
        initSettings()
        casper.cozy.selectMessage "DoveCot", "Draft", "my draft subject", (messageID) ->
            casper.waitForSelector "#email-compose .rt-editor", ->
                test.assertExists '#email-compose', 'Compose form is displayed'
                values = casper.getFormValues('#email-compose form')
                test.assertEquals values["compose-bcc"], "bcc@cozy.io"
                test.assertEquals values["compose-cc"], "cc@cozy.io"
                test.assertEquals values["compose-subject"], "my draft subject"
                test.assertEquals values["compose-to"], "to@cozy.io"
                test.assertEquals casper.fetchText('.rt-editor'), "Hello,Join us now and share the software", "message HTML"
                message = casper.evaluate ->
                    return window.cozyMails.getCurrentMessage()
                test.assertEquals message.text, "_Hello,_\nJoin us now and share the software", "messageText"
                casper.click '.composeToolbox .btn-delete'
                casper.waitWhileSelector "#email-compose h3[data-message-id=#{messageID}]", ->
                    test.pass 'Compose closed'
                    casper.reload ->
                        test.assertDoesntExist "li.message[data-message-id='#{messageID}']", "message deleted"

    casper.run ->
        test.done()
