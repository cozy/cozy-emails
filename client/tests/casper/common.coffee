require = patchRequire global.require
utils   = require "utils"
system  = require "system"
x       = require('casper.js').selectXPath

dev = false

if utils.cmpVersion("1.1", phantom.casperVersion) > 0
    casper.die "You need at least CasperJS 1.1"

casper.cozy =
    startUrl: system.env.COZY_URL

casper.cozy.selectMessage = (account, box, subject, messageID, cb) ->
    if typeof messageID is 'function'
        cb = messageID
    accounts = casper.evaluate ->
        accounts = {}
        Array.prototype.forEach.call document.querySelectorAll("#account-list > li"), (e) ->
            accounts[e.querySelector('.item-label').textContent.trim()] = e.dataset.reactid
        return accounts
    id = accounts[account]
    casper.test.assert (typeof id is 'string'), "Account #{account} found"
    casper.click "[data-reactid='#{id}'] a"
    casper.waitForSelector "[data-reactid='#{id}'].active", ->
        mailboxes = casper.evaluate ->
            mailboxes = {}
            Array.prototype.forEach.call document.querySelectorAll("#account-list > li.active .mailbox-list > li"), (e) ->
                mailboxes[e.querySelector('.item-label').textContent.trim()] = e.dataset.reactid
            return mailboxes
        id = mailboxes[box]
        casper.click "[data-reactid='#{id}'] .item-label"
        casper.waitForSelector "[data-reactid='#{id}'].active", ->
            if typeof messageID is 'string'
                subjectSel = "[data-message-id='#{messageID}'] a .preview"
            else
                subjectSel = x "//span[(contains(normalize-space(.), '#{subject}'))]"
            casper.waitForSelector subjectSel, ->
                casper.click subjectSel
                casper.waitForSelector x("//h3[(contains(normalize-space(.), '#{subject}'))]"), ->
                    casper.test.pass "Message #{subject} selected"
                    cb()
                , ->
                    casper.test.fail "Error displaying #{subject}"
            , ->
                casper.test.fail "No message with subject #{subject}"
        , ->
            casper.test.fail "Unable to go to mailbox #{box}"
    , ->
        casper.test.fail "Unable to go to account #{account}"

if not casper.cozy.startUrl?
    casper.die "Please set the base URL into COZY_URL environment variable"

exports.init = (casper) ->
    dev = casper.cli.options.dev?

    if dev
        casper.options.verbose = true
        casper.options.logLevel = 'debug'
    casper.options.waitTimeout = 15000
    casper.options.timeout = 120000
    casper.options.viewportSize = {width: 1024, height: 768}
    casper.on 'exit', (res) ->
        if res isnt 0 or dev
            casper.capture("last.png")
            require('fs').write('last.html', this.getHTML())
    casper.on "remote.message", (msg) ->
        casper.echo "Message: " + msg, "INFO"
    casper.on 'resource.requested', (request) ->
        if dev
            casper.echo "--->" + request.url
            utils.dump request
    casper.on "page.error", (msg, trace) ->
        casper.echo "Error: " + msg, "ERROR"
        utils.dump trace.slice 0, 2
    casper.on "load.finished", ->
        casper.evaluate ->
            if not window.cozyMails? then return
            # ensure locale is english
            window.cozyMails.setLocale 'en', true
            # hide toasts
            document.querySelector(".toasts-container").classList.add 'hidden'
            # deactivate all plugins
            PluginUtils = require '../utils/plugin_utils'
            for pluginName, pluginConf of window.plugins
                PluginUtils.deactivate pluginName
