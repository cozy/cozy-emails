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
        casper.waitForSelector "#mailbox-config", ->
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
                casper.waitForSelector "#mailbox-config", ->
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
        casper.evaluate ->
            # Create some test contacts
            ContactActionCreator = require '../actions/contact_action_creator'
            ContactActionCreator.createContact name: 'Alice', address: 'alice@casper.cozy'
            ContactActionCreator.createContact name: 'Bob', address: 'bob@casper.cozy'
        test.assertDoesntExist '.modal-dialog', 'No modal'
        casper.click '#compose-to + .btn-cozy'
        casper.waitForSelector '.modal-dialog', ->
            test.pass 'Modal displayed'
            casper.click '.modal-footer .btn'
            casper.waitWhileSelector '.modal-dialog', ->
                test.pass 'Modal hidden'

    casper.then ->
        test.comment "Select contacts"
        casper.click '#compose-to + .btn-cozy'
        casper.waitForSelector '.modal-dialog', ->
            test.assertDoesntExist '.contact-list', 'No contacts displayed'
            casper.fillSelectors 'form',
                '.search-input': 'casper.cozy'
            casper.click '.contact-form .search-btn'
            casper.waitForSelector '.contact-list', ->
                test.assertExist '.contact-list li', "Some contacts found"
                contact = casper.fetchText '.contact-list li:nth-of-type(1)'
                test.assert /casper\.cozy/.test(contact), "Contact match"
                casper.click '.contact-list li:nth-of-type(1) '
                casper.waitWhileSelector '.modal-dialog', ->
                    values = casper.getFormValues('#email-compose form')
                    test.assert values["compose-to"] is contact, "Contact added"
                    casper.click '#compose-to + .btn-cozy'
                    casper.waitForSelector '.modal-dialog', ->
                        test.assertDoesntExist '.contact-list', 'No contacts displayed'
                        casper.fillSelectors 'form',
                            '.search-input': 'casper.cozy'
                        casper.click '.contact-form .search-btn'
                        casper.waitForSelector '.contact-list', ->
                            contact2 = casper.fetchText '.contact-list li:nth-of-type(2)'
                            casper.click '.contact-list li:nth-of-type(2) '
                            casper.waitWhileSelector '.modal-dialog', ->
                                values = casper.getFormValues('#email-compose form')
                                test.assertEqual values["compose-to"], "#{contact}, #{contact2}", "Contact added"

    casper.run ->
        test.done()

