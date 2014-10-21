require = patchRequire global.require
init    = require("../common").init
utils   = require "/usr/local/lib/node_modules/casperjs/modules/utils.js"

casper.test.begin 'Test compose in HTML', (test) ->
    init casper

    casper.start "http://localhost:9125/#settings", ->
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


    casper.run ->
        test.done()

