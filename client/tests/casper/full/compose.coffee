require = patchRequire global.require
init    = require("../common").init
utils   = require "utils.js"

casper.test.begin 'Test compose', (test) ->
    init casper

    casper.start casper.cozy.startUrl + "#settings", ->
        test.comment "Compose in HTML"
        accountSel = "#account-list .menu-item.account .item-label"
        accounts = casper.getElementsInfo accountSel
        ids = accounts.map (e) -> return e.attributes['data-account-id']
        casper.waitForSelector "#settings", ->
            inHTML = casper.evaluate ->
                return document.getElementById("settings-composeInHTML").checked
            doTest = ->
                if inHTML
                    test.assertExist "#email-compose div[contenteditable]", "Compose in HTML"
                    test.assertDoesntExist "#email-compose textarea.editor", "Compose in HTML"
                else
                    test.assertDoesntExist "#email-compose div[contenteditable]", "Compose in Text"
                    test.assertExist "#email-compose textarea.editor", "Compose in Text"
            casper.click "#menu .compose-action"
            casper.waitForSelector "#email-compose", ->
                doTest()
                casper.click "#menu .settings-action"
                casper.waitForSelector "#settings", ->
                    casper.click "#settings-composeInHTML"
                    inHTML = not inHTML
                    casper.wait 5000, ->
                        casper.click "#menu .compose-action"
                        casper.waitForSelector "#email-compose", ->
                            doTest()

    casper.then ->
        casper.open casper.cozy.startUrl + "#compose", ->
            test.comment "Field visibility"
            test.assertNotVisible '#compose-cc', 'Cc hidden'
            test.assertNotVisible '#compose-bcc', 'Bcc hidden'
            casper.click '.compose-toggle-cc'
            casper.click '.compose-toggle-bcc'
            test.assertVisible '#compose-cc', 'Cc shown'
            test.assertVisible '#compose-bcc', 'Bcc shown'
            casper.click '.compose-toggle-cc'
            casper.click '.compose-toggle-bcc'
            test.assertNotVisible '#compose-cc', 'Cc hidden'
            test.assertNotVisible '#compose-bcc', 'Bcc hidden'

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

    casper.run ->
        test.done()

