if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"
x     = require('casper.js').selectXPath

casper.test.begin 'Test filters', (test) ->
    init casper

    filter = null

    casper.start casper.cozy.startUrl, ->
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    casper.then ->
        test.comment "Filtering on sender"
        casper.cozy.selectAccount 'Gmail', 'INBOX', ->
            users = casper.getElementsInfo('.address-list:first-of-type .address-item').map (item) ->
                return item.text.trim()
            filter = users[0]
            casper.fillSelectors 'form.search', {'input[name=searchterm]': filter}, false
            casper.click 'form.search button.fa-check'
            casper.waitWhileSelector '.main-content', ->
                casper.waitForSelector '.main-content', ->
                    filtered = casper.getElementsInfo('.address-list:first-of-type .address-item').map (item) ->
                        return item.text.trim()
                    test.assertTruthy(filtered.every( (item) -> return item is filter), "Messages are filtered")

    casper.then ->
        test.comment "Changing folder clears filters"
        casper.cozy.selectAccount 'Gmail', 'Important', ->
            values = casper.getFormValues 'form.search'
            test.assertEquals '', values.searchterm, 'Search form is empty'
            test.assertDoesntExist 'form.search button.fa-check', 'Search form is empty'
            users = casper.getElementsInfo('.address-list:first-of-type .address-item').map (item) ->
                return item.text.trim()
            filtered = users.filter (item) -> return item isnt filter
            test.assertNotEquals 0, filtered.length, "List is not filtered"

    casper.then ->
        test.comment "Filtering on attachments"
        casper.cozy.selectAccount 'Gmail', 'Important', ->
            test.assertDoesntExist '.messages-list .filters [aria-selected="true"]', "No filter selected"
            casper.click '.messages-list .filters .fa-paperclip'
            casper.waitForSelector '.listEmpty', ->
                test.pass 'No message with attachments'
                test.assertExists '.messages-list .filters [aria-selected="true"]', "Filter selected"
                casper.cozy.selectAccount 'DoveCot', 'INBOX', ->
                    test.assertDoesntExist '.messages-list .filters [aria-selected="true"]', "No filter selected"
                    test.assertExists '.main-content', 'Messages displayed'

    casper.then ->
        test.comment "Filtering should close conversation panel"
        casper.cozy.selectMessage 'DoveCot', 'INBOX', null, (subject, messageID) ->
            test.assertExists '.conversation.panel', "Conversation panel is displayed"
            casper.click '.messages-list .filters .fa-paperclip'
            casper.waitForSelector '.messages-list .filters [aria-selected=true] .fa-paperclip', ->
                casper.waitForSelector '.listEmpty', ->
                    test.assertDoesntExist '.conversation.panel', "Conversation panel is not displayed"

    casper.then ->
        test.comment "Clearing search filter"
        casper.cozy.selectAccount 'Gmail', 'INBOX', ->
            users = casper.getElementsInfo('.address-list:first-of-type .address-item').map (item) ->
                return item.text.trim()
            filter = users[0]
            casper.fillSelectors 'form.search', {'input[name=searchterm]': filter}, false
            casper.click 'form.search button.fa-check'
            casper.waitWhileSelector '.main-content', ->
                casper.waitForSelector '.main-content', ->
                    filtered = casper.getElementsInfo('.address-list:first-of-type .address-item').map (item) ->
                        return item.text.trim()
                    test.assertTruthy(filtered.every( (item) -> return item is filter), "Messages are filtered")
                    casper.click 'form.search button.fa-close'
                    casper.waitWhileSelector '.main-content', ->
                        casper.waitForSelector '.main-content', ->
                            values = casper.getFormValues 'form.search'
                            test.assertEquals '', values.searchterm, 'Search form is empty'
                            test.assertDoesntExist 'form.search button.fa-check', 'Search form is empty'
                            users = casper.getElementsInfo('.address-list:first-of-type .address-item').map (item) ->
                                return item.text.trim()
                            filtered = users.filter (item) -> return item isnt filter
                            test.assertNotEquals 0, filtered.length, "List is not filtered"

    casper.run ->
        test.done()
