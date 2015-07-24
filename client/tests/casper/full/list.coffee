if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"
x     = require('casper.js').selectXPath

casper.test.begin 'List action', (test) ->
    init casper

    messageID = 'mail.cozy.io'

    casper.start casper.cozy.startUrl, ->
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    casper.then ->
        test.comment "badges"
        base = ".messages-list li.message[data-message-id$='#{messageID}']"
        casper.cozy.selectAccount "DoveCot", "Test Folder", ->
            test.assertElementCount '.messages-list .conversation-length', 2, 'Badges'
            badges = casper.fetchText "#{base} .conversation-length"
            test.assertEquals badges, '5', 'Badges value'
            infos = casper.getElementInfo base
            messageID = infos.attributes['data-message-id']

    casper.then ->
        test.comment "Delete conversation"
        if casper.getEngine() isnt 'slimer'
            test.comment "Skipping, as PhantomJS doesn't support PATCH verb"
            test.skip 1
        else
            base = ".messages-list li.message[data-message-id$='#{messageID}']"
            casper.mouse.move ".messages-list li.message[data-message-id$='#{messageID}']"
            casper.click ".messages-list li.message[data-message-id$='#{messageID}'] i.select"
            casper.waitForSelector '.messages-list aside .fa-trash-o', ->
                casper.click '.messages-list aside .fa-trash-o'
                casper.waitUntilVisible '.modal-dialog',  ->
                    confirm = casper.fetchText('.modal-body').trim()
                    test.assertEquals confirm, "Do you really want to delete this conversation ?", "Confirmation dialog"
                    casper.click ".modal-dialog .btn:not(.btn-cozy-non-default)"
                    casper.waitWhileSelector base, ->
                        test.pass 'Conversation deleted'

    casper.then ->
        test.comment "Move conversation"
        if casper.getEngine() isnt 'slimer'
            test.comment "Skipping, as PhantomJS doesn't support PATCH verb"
            test.skip 1
        else
            casper.cozy.selectAccount "DoveCot", "Trash", ->
                base = ".messages-list li.message[data-message-id$='#{messageID}']"
                test.assertExists base, 'Message is in trash'
                casper.mouse.move "#{base}"
                casper.click "#{base} i.select"
                casper.waitForSelector '.messages-list aside .fa-cog', ->
                    casper.click '.messages-list aside .fa-cog'
                    casper.waitUntilVisible ".messages-list aside .menu-action li[data-reactid$='f5cbd722-c3f9-4f6e-73d0-c75ddf65a2f1'] ", ->
                        casper.click ".messages-list aside .menu-action li[data-reactid$='f5cbd722-c3f9-4f6e-73d0-c75ddf65a2f1'] a"
                        casper.waitWhileSelector base, ->
                            casper.cozy.selectAccount "DoveCot", "Test Folder", ->
                                test.assertExists base, 'Message moved'
                                badges = casper.fetchText "#{base} .conversation-length"
                                test.assertEquals badges, '5', 'Badges value'

    casper.run ->
        test.done()


