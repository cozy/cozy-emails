if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init  = require(fs.workingDirectory + "/client/tests/casper/common").init
utils = require "utils.js"
x     = require('casper.js').selectXPath

doSelect = (n, cb) ->
    casper.click ".messages-list li.message:nth-of-type(#{n})"
    casper.waitForSelector ".messages-list li.message:nth-of-type(#{n}).active", ->
        infos = casper.getElementInfo '.messages-list li.message.active'
        conversationID = infos.attributes['data-conversation-id']
        casper.test.assertExists "h3.conversation-title[data-conversation-id='#{conversationID}']", "Message #{n} selected"
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
    casper.waitForSelector ".messages-list li.message:nth-of-type(#{next}).active", ->
        infos = casper.getElementInfo '.messages-list li.message.active'
        messageID = infos.attributes['data-message-id']
        casper.test.assertExists "h3.conversation-title[data-message-id='#{messageID}']", "Message #{next} selected"
        if cb?
            cb()

casper.test.begin 'Test Message Selection', (test) ->
    init casper

    casper.start casper.cozy.startUrl, ->
        casper.waitForSelector "aside[role=menubar][aria-expanded=true]"

    casper.then ->
        test.comment "Selecting by click in conversation mode"
        casper.cozy.selectAccount "DoveCot", "Test Folder", ->
            test.assertExists '.messages-list li.message:nth-of-type(1).active', 'First message selected'
            doSelect 3, ->
                doSelect 1, ->
                    # force folder update
                    casper.cozy.selectAccount "DoveCot", "INBOX"

    casper.run ->
        test.done()

