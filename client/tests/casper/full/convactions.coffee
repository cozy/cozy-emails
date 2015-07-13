if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"
x     = require('casper.js').selectXPath

casper.test.begin 'Test Actions on conversations', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    casper.then ->
        if casper.getEngine() isnt 'slimer'
            test.comment "Skipping, as PhantomJS doesn't support PATCH verb"
            test.skip 1
        else
            test.comment "Move Message"

            casper.cozy.selectMessage "DoveCot", "Test Folder", "Re: troll", (subject, messageID, conversationID) ->
                test.assertExist ".messages-list li[data-conversation-id='#{conversationID}']"
                nbMessages = casper.getElementsInfo(".messages-list li.message").length
                nbInConv = casper.fetchText ".messages-list li.message.active .badge.conversation-length"
                casper.mouse.move ".messages-list li.message.active"
                casper.click ".messages-list li.message.active i.select"
                casper.waitUntilVisible '.messages-list aside .menu-action button', ->
                    casper.click '.messages-list aside .menu-action button'
                    casper.waitUntilVisible '.messages-list aside .menu-action a[data-reactid*="0b3a2b31-7acb-dbab-d57f-3050ae2c78c5"]', ->
                        casper.click '.messages-list aside .menu-action a[data-reactid*="0b3a2b31-7acb-dbab-d57f-3050ae2c78c5"]'
                        casper.waitFor ->
                            casper.evaluate ->
                                isPresent  = document.querySelectorAll('.messages-list li[data-conversation-id="20141106092130.GF5642@mail.cozy.io"]').length
                                nbMessages = document.querySelectorAll('.messages-list li.message').length
                                return (isPresent is 0 and nbMessages is 2)
                            test.pass "Message no more in folder"
                            casper.evaluate ->
                                window.cozyMails.messageClose()
                            casper.cozy.selectMessage "DoveCot", "Flagged Email", "Re: troll", (subject, messageID) ->
                                test.pass "Message Moved"
                                test.assertEquals casper.fetchText(".messages-list li.message[data-conversation-id='#{conversationID}'] .badge.conversation-length"),
                                    nbInConv, "All messages in conv moved"
                                casper.click ".conversation .message.active .messageToolbox button.move"
                                boxSelector = ".conversation .message.active .messageToolbox [data-reactid$='f5cbd72*-c3f9-4f6e-73d0-c75ddf65a2f1']"
                                casper.waitUntilVisible boxSelector, ->
                                    casper.click boxSelector
                                    casper.waitWhileSelector ".messages-list li.message[data-conversation-id='#{conversationID}']", ->
                                        test.pass "Message no more in folder"
                                        casper.cozy.selectMessage "DoveCot", "Test Folder", subject, messageID, ->
                                            test.pass "Message moved back to original folder"
                                            test.assertEquals casper.getElementsInfo(".messages-list li.message").length, nbMessages,
                                                "message is back"
                                            test.assertEquals casper.fetchText(".messages-list li.message.active .badge.conversation-length"),
                                                nbInConv, "All messages in conv moved"


    casper.run ->
        test.done()
