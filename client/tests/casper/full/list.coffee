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

    casper.start casper.cozy.startUrl

    casper.then ->
        test.comment "badges"
        base = ".message-list li.message[data-message-id$='#{messageID}']"
        casper.evaluate ->
            window.cozyMails.setSetting 'displayConversation', false
            window.cozyMails.setSetting 'displayPreview', false
        casper.cozy.selectAccount "DoveCot", "Test Folder", ->
            test.assertNotExists '.message-list .badge.conversation-length', 'No badge'
            casper.evaluate ->
                window.cozyMails.setSetting 'displayConversation', true
            casper.cozy.selectAccount "DoveCot", "Test Folder", ->
                test.assertElementCount '.message-list .badge.conversation-length', 1, 'Badges'
                badges = casper.fetchText "#{base} .badge.conversation-length"
                test.assertEquals badges, '5', 'Badges value'
                infos = casper.getElementInfo base
                messageID = infos.attributes['data-message-id']

    casper.then ->
        test.comment "Delete conversation"
        if casper.getEngine() isnt 'slimer'
            test.comment "Skipping, as PhantomJS doesn't support PATCH verb"
            test.skip 1
        else
            confirm = ''
            casper.evaluate ->
                window.cozyMails.setSetting 'messageConfirmDelete', true
                window.cozyMails.setSetting 'displayConversation', true
                window.cozyMails.setSetting 'displayPreview', false
                window.cozytest = {}
                window.cozytest.confirm = window.confirm
                window.confirm = (txt) ->
                    window.cozytest.confirmTxt = txt
                    return true
                return true
            base = ".message-list li.message[data-message-id$='#{messageID}']"
            casper.mouse.move ".message-list li.message[data-message-id$='#{messageID}'] .fa-user"
            casper.click ".message-list li.message[data-message-id$='#{messageID}'] input[type=checkbox]"
            casper.waitForSelector '.message-list-actions .btn.trash', ->
                casper.click '.message-list-actions .btn.trash'
                casper.waitFor ->
                    confirm = casper.evaluate ->
                        return window.cozytest.confirmTxt
                    return confirm?
                , ->
                    test.assertEquals confirm, "Do you really want to delete this conversation ?", "Confirmation dialog"
                    casper.waitWhileSelector base, ->
                        test.pass 'Conversation deleted'

    casper.then ->
        test.comment "Move conversation"
        if casper.getEngine() isnt 'slimer'
            test.comment "Skipping, as PhantomJS doesn't support PATCH verb"
            test.skip 1
        else
            casper.evaluate ->
                window.cozyMails.setSetting 'displayConversation', true
                window.cozyMails.setSetting 'displayPreview', false
            casper.cozy.selectAccount "DoveCot", "Trash", ->
                base = ".message-list li.message[data-message-id$='#{messageID}']"
                test.assertExists base, 'Message is in trash'
                casper.mouse.move "#{base} .fa-user"
                casper.click "#{base} input[type=checkbox]"
                casper.waitForSelector '.message-list-actions .btn.move', ->
                    casper.click '.message-list-actions .btn.move'
                    casper.waitUntilVisible ".message-list-actions .menu-move a[data-value='f5cbd722-c3f9-4f6e-73d0-c75ddf65a2f1']", ->
                        casper.click ".message-list-actions .menu-move a[data-value='f5cbd722-c3f9-4f6e-73d0-c75ddf65a2f1']"
                        casper.waitWhileSelector base, ->
                            casper.cozy.selectAccount "DoveCot", "Test Folder", ->
                                test.assertExists base, 'Message moved'
                                badges = casper.fetchText "#{base} .badge.conversation-length"
                                test.assertEquals badges, '5', 'Badges value'

    casper.then ->
        test.comment "End"
        casper.evaluate ->
            window.cozyMails.setSetting 'displayPreview', true

    casper.run ->
        test.done()


