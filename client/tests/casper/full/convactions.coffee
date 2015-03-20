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
        casper.evaluate ->
            window.cozyMails.setSetting 'messageDisplayHTML', true
            window.cozyMails.setSetting 'messageDisplayImages', false
            window.cozyMails.setSetting 'displayConversation', true
            window.cozyMails.setSetting 'displayPreview', true
            window.cozyMails.setSetting 'messageConfirmDelete', true
            window.cozyMails.setSetting 'composeInHTML', true

    casper.then ->
        if casper.getEngine() isnt 'slimer'
            test.comment "Skipping, as PhantomJS doesn't support PATCH verb"
            test.skip 1
        else
            test.comment "Move Message"

            casper.cozy.selectMessage "DoveCot", "Test Folder", "Re: troll", (subject, messageID) ->
                nbMessages = casper.getElementsInfo(".message-list li.message").length
                nbInConv = casper.fetchText ".message-list li.message.active .badge.conversation-length"
                casper.mouse.move ".message-list li.message.active .fa-user"
                casper.click ".message-list li.message.active input[type=checkbox]"
                casper.waitUntilVisible '.message-list-actions .menu-move button', ->
                    casper.click '.message-list-actions .menu-move button'
                    casper.waitUntilVisible '.message-list-actions .menu-move a[data-value="0b3a2b31-7acb-dbab-d57f-3050ae2c78c5"]', ->
                        casper.click '.message-list-actions .menu-move a[data-value="0b3a2b31-7acb-dbab-d57f-3050ae2c78c5"]'
                        casper.waitWhileVisible ".message-list li[data-message-id='#{messageID}']", ->
                            test.assertEquals casper.getElementsInfo(".message-list li.message").length, nbMessages - 1,
                                "Message no more in folder"
                            casper.evaluate ->
                                window.cozyMails.messageClose()
                            casper.cozy.selectMessage "DoveCot", "Flagged Email", "Re: troll", (subject, messageID) ->
                                test.pass "Message Moved"
                                test.assertEquals casper.fetchText(".message-list li.message[data-message-id='#{messageID}'] .badge.conversation-length"),
                                    nbInConv, "All messages in conv moved"
                                casper.click ".conversation .message.active .messageToolbox button.move"
                                boxSelector = ".conversation .message.active .messageToolbox [data-value='f5cbd722-c3f9-4f6e-73d0-c75ddf65a2f1']"
                                casper.waitUntilVisible boxSelector, ->
                                    casper.click boxSelector
                                    casper.waitWhileSelector ".message-list li.message[data-message-id='#{messageID}']", ->
                                        test.pass "Message no more in folder"
                                        casper.cozy.selectMessage "DoveCot", "Test Folder", subject, messageID, ->
                                            test.pass "Message moved back to original folder"
                                            test.assertEquals casper.getElementsInfo(".message-list li.message").length, nbMessages,
                                                "message is back"
                                            test.assertEquals casper.fetchText(".message-list li.message.active .badge.conversation-length"),
                                                nbInConv, "All messages in conv moved"


    casper.run ->
        test.done()
