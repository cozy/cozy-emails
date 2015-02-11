if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"

casper.test.begin 'Test compose', (test) ->
    init casper

    casper.start casper.cozy.startUrl + "#settings", ->
        test.comment "Compose in HTML"
        accountSel = "#account-list .menu-item.account .item-label"
        accounts = casper.getElementsInfo accountSel
        ids = accounts.map (e) -> return e.attributes['data-account-id']
        casper.waitForSelector "#settings", ->
            casper.evaluate ->
                window.cozyMails.setSetting 'composeInHTML', true
            selHtml = "#email-compose div[contenteditable]"
            selText = "#email-compose textarea.editor"
            casper.click "#menu .compose-action"
            casper.waitForSelector selHtml, ->
                test.assertDoesntExist selText, 'Compose in HTML'
                casper.click "#menu .settings-action"
                casper.waitForSelector "#settings", ->
                    casper.evaluate ->
                        window.cozyMails.setSetting 'composeInHTML', false
                    casper.click "#menu .compose-action"
                    casper.waitForSelector selText, ->
                        test.assertDoesntExist selHtml, 'Compose in Text'

    casper.then ->
        test.comment "Field visibility"
        test.assertNotVisible '.form-group.compose-cc', 'Cc hidden'
        test.assertNotVisible '.form-group.compose-bcc', 'Bcc hidden'
        casper.click '.compose-toggle-cc'
        casper.click '.compose-toggle-bcc'
        test.assertVisible '.form-group.compose-cc', 'Cc shown'
        test.assertVisible '.form-group.compose-bcc', 'Bcc shown'
        casper.click '.compose-toggle-cc'
        casper.click '.compose-toggle-bcc'
        test.assertNotVisible '.form-group.compose-cc', 'Cc hidden'
        test.assertNotVisible '.form-group.compose-bcc', 'Bcc hidden'

    ### @FIXME this test keeps failing on Travis
    casper.then ->
        test.comment "Compose to contacts"
        test.assertNotVisible '.contact-list', 'No contacts displayed'
        casper.fillSelectors 'form',
            '#compose-to': 'casper.cozy'
        casper.click '#compose-to + .btn-cozy'
        casper.waitUntilVisible '.contact-list', ->
            test.assertExist '.contact-list li', "Some contacts found"
            contact = casper.fetchText '.contact-form.open .contact-list li:nth-of-type(1)'
            test.assert /casper\.cozy/.test(contact), "Contact match"
            casper.click '.contact-list li:nth-of-type(1) '
            casper.waitWhileVisible '.contact-list', ->
                values = casper.getFormValues('#email-compose form')
                test.assertEquals values["compose-to"], "#{contact}, ", "Contact added"
                casper.fillSelectors 'form',
                    '#compose-to': "#{contact}, casper.cozy"
                casper.click '#compose-to + .btn-cozy'
                casper.waitUntilVisible '.contact-list', ->
                    test.assertExist '.contact-list li', "Some contacts found"
                    contact2 = casper.fetchText '.contact-form.open .contact-list li:nth-of-type(1)'
                    test.assert /casper\.cozy/.test(contact), "Contact match"
                    casper.click '.contact-list li:nth-of-type(1) '
                    casper.waitWhileVisible '.contact-list', ->
                        values = casper.getFormValues('#email-compose form')
                        test.assert values["compose-to"] is "#{contact}, #{contact2}, ", "Contact added"
    ###

    casper.run ->
        test.done()

