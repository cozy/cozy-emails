if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"

sendKey = (key) ->
    casper.evaluate (key) ->
        Mousetrap.trigger key
    , key

messages = []


casper.test.begin 'Test keyboard shortcuts', (test) ->
    init casper

    filter = null

    casper.start casper.cozy.startUrl, ->
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    casper.then ->
        test.comment "Keyboard navigation"
        casper.cozy.selectAccount 'Gmail', 'noconv', ->
            casper.getElementsInfo('.list-unstyled > .message').forEach (elmt) ->
                messages.push elmt.attributes['data-conversation-id']
            if casper.exists '.conversation.panel'
                test.fail 'No message should be displayed'
            sendKey 'down'
            casper.waitForSelector '.conversation.panel', ->
                test.assertExists "[data-conversation-id='#{messages[0]}'].active", "Message selected"
                sendKey 'down'
                casper.waitForSelector "[data-conversation-id='#{messages[1]}'].active", ->
                    test.pass "Next message selected"
                    sendKey 'up'
                    casper.waitForSelector "[data-conversation-id='#{messages[0]}'].active", ->
                    test.pass "Prev message selected"

    casper.then ->
        test.comment "Delete"
        if casper.getEngine() isnt 'slimer'
            test.comment "Skipping, as PhantomJS 1.x doesn't support creating MouseEvent verb"
            test.skip 1
        else
            if casper.exists '.modal'
                test.fail 'No modal should be displayed'
            sendKey 'del'
            casper.waitForSelector '.modal', ->
                test.pass 'Modal window displayed'
                sendKey 'enter'
                casper.waitWhileSelector '.modal', ->
                    test.pass 'Modal window closed'
                    casper.waitWhileSelector "[data-conversation-id='#{messages[0]}']", ->
                        test.assertExists "[data-conversation-id='#{messages[1]}'].active", "MessageDeleted"
                        test.assertExists "h3[data-conversation-id='#{messages[1]}']", "Next message displayed"
                        sendKey 'esc'
                        casper.waitWhileSelector '.conversation.panel', ->
                            test.pass "Message closed"


    casper.run ->
        test.done()

