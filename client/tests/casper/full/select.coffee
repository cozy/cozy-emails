if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"
x     = require('casper.js').selectXPath

doSelect = (n, cb) ->
    casper.click ".message-list li.message:nth-of-type(#{n})"
    casper.waitForSelector ".message-list li.message:nth-of-type(#{n}).active", ->
        infos = casper.getElementInfo '.message-list li.message.active'
        messageID = infos.attributes['data-message-id']
        casper.test.assertExists "h3.conversation-title[data-message-id='#{messageID}']", "Message #{n} selected"
        if cb?
            cb()

doKey = (key, next, cb) ->
    #casper.page.sendEvent('keydown', casper.page.event.key.Down)
    #casper.page.sendEvent('keyup', casper.page.event.key.Down)
    #casper.page.sendEvent('keypress', casper.page.event.key.Down)
    casper.evaluate (key) ->
        console.log key
        window.Mousetrap.trigger('j')
    , 'j'
    casper.waitForSelector ".message-list li.message:nth-of-type(#{next}).active", ->
        infos = casper.getElementInfo '.message-list li.message.active'
        messageID = infos.attributes['data-message-id']
        casper.test.assertExists "h3.conversation-title[data-message-id='#{messageID}']", "Message #{next} selected"
        if cb?
            cb()

casper.test.begin 'Test Message Selection', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        test.comment "Selecting by click in conversation mode"
        casper.cozy.selectAccount "DoveCot", "Test Folder", ->
            test.assertExists '.message-list li.message:nth-of-type(1).active', 'First message selected'
            doSelect 3, ->
                doSelect 1, ->
                    # force folder update
                    casper.cozy.selectAccount "DoveCot", "INBOX"

    ###
    casper.then ->
        test.comment "Keyboard navigation"
        casper.evaluate ->
            window.cozyMails.setSetting 'displayConversation', false
        casper.cozy.selectAccount "DoveCot", "Test Folder", ->
            test.assertExists '.message-list li.message:nth-of-type(1).active', 'First message selected'
            casper.wait 5000, ->
                doKey 'down', 2, ->
                    doKey 'down', 3, ->
                        doKey 'j', 4, ->
                            doKey 'k', 3, ->
                                doKey 'up', 2
    ###

    casper.then ->
        test.comment "Select mode togle"
        test.assertNotVisible '.message-list input[type=checkbox]', 'No checkbox displayed'
        casper.click ".message-list li.message:nth-of-type(1) input[type=checkbox]"
        test.assertVisible ".message-list li.message:nth-of-type(1) input[type=checkbox]:checked", 'Checkbox checked'
        test.assertVisible ".message-list li.message:nth-of-type(2) input[type=checkbox]", 'Other checkboxes visibles'
        casper.click ".message-list li.message:nth-of-type(1) input[type=checkbox]"
        test.assertNotVisible '.message-list input[type=checkbox]', 'No checkbox displayed'


    casper.run ->
        test.done()

