require = patchRequire global.require
init    = require("../common").init
utils   = require "/usr/local/lib/node_modules/casperjs/modules/utils.js"

casper.test.begin 'Test accounts', (test) ->
    init casper

    casper.start "http://localhost:9125/", ->
        accountSel = "#account-list .menu-item.account"
        test.assertExists accountSel, "Accounts in menu"

    casper.then ->
        accountSel = "#account-list .menu-item.account"
        accounts = casper.getElementsInfo accountSel
        casper.eachThen accounts, (response) ->
            account = response.data
            id = account.attributes['data-reactid']
            casper.click "[data-reactid='#{id}']"
            casper.waitForSelector ".active[data-reactid='#{id}']", ->
                test.pass "Account #{account.text} selected"
                if casper.exists ".message-list .message"
                    casper.click ".message-list .message a"
                    casper.waitUntilVisible ".conversation"
            , ->
                test.fail "Unable to select account #{account.text}"

    casper.run ->
        test.done()

