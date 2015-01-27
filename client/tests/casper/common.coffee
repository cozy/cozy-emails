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
        getAccounts = ->
            _accounts = {}
            Array.prototype.forEach.call document.querySelectorAll("#account-list > li"), (e) ->
                accountName = e.querySelector('.item-label').textContent.trim()
                _accounts[accountName] = e.dataset.reactid
            return _accounts
        return getAccounts()
    id = accounts[account]
    if not id?
        casper.test.fail "Unable to find account #{account}"
    if not casper.exists "[data-reactid='#{id}'].active"
        casper.click "[data-reactid='#{id}'] a"
    casper.waitForSelector "[data-reactid='#{id}'].active", ->
        mailboxes = casper.evaluate ->
            getMailboxes = ->
                mailboxes = {}
                mailboxesSel = '#account-list > li.active .mailbox-list > li'
                Array.prototype.forEach.call document.querySelectorAll(mailboxesSel), (e) ->
                    mailboxName = e.querySelector('.item-label').textContent.trim()
                    mailboxes[mailboxName] = e.dataset.reactid
                return mailboxes
            return getMailboxes()
        id = mailboxes[box]
        if not id?
            casper.test.fail "Unable to find mailbox #{box} in #{account}"
        casper.click "[data-reactid='#{id}'] .item-label"
        casper.waitForSelector "[data-reactid='#{id}'].active", ->
            casper.waitForSelector ".message-list li.message", ->
                if typeof messageID is 'string'
                    subjectSel  = ".message-list li[data-message-id='#{messageID}'] a .preview"
                    subjectDone = "h3[data-message-id='#{messageID}']"
                else if typeof subject is 'string'
                    subjectSel  = x "//span[(contains(normalize-space(.), '#{subject}'))]"
                    subjectDone = x "//h3[(contains(normalize-space(.), '#{subject}'))]"
                else
                    subjectSel = '.message-list li.message:nth-of-type(1) .title'
                casper.waitForSelector subjectSel, ->
                    if not (typeof subject is 'string')
                        subject = casper.fetchText subjectSel
                        subjectDone = x "//h3[(contains(normalize-space(.), '#{subject}'))]"
                    casper.click subjectSel
                    casper.waitForSelector subjectDone, ->
                        #casper.test.pass "Message #{subject} selected"
                        cb(subject)
                    , ->
                        casper.test.fail "Error displaying #{subject}"
                , ->
                    casper.test.fail "No message matching #{subjectSel}"
            , ->
                casper.test.fail "No message in #{account}/#{box}"
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
    casper.options.waitTimeout = 60000
    casper.options.timeout = 200000
    casper.options.viewportSize = {width: 1024, height: 768}
    casper.on 'exit', (res) ->
        if res isnt 0 or dev
            casper.capture("last.png")
            require('fs').write('last.html', this.getHTML())
    casper.on "remote.message", (msg) ->
        if typeof msg isnt 'string'
            msg = utils.serialize(msg, 2)
        casper.echo "Message: " + msg, "INFO"
    casper.on 'resource.requested', (request) ->
        if dev
            casper.echo "--->" + request.url
            utils.dump request
    casper.on "page.error", (msg, trace) ->
        casper.echo "Error: " + msg, "ERROR"
        utils.dump trace.slice 0, 2
    casper.on "load.finished", ->
        if casper.getTitle() isnt 'Cozy Emails'
            return
        accounts = casper.evaluate ->
            if window.cozyMails?
                # ensure locale is english
                window.cozyMails.setLocale 'en', true
                # hide toasts
                document.querySelector(".toasts-container").classList.add 'hidden'
                # deactivate all plugins
                PluginUtils = require '../utils/plugin_utils'
                for pluginName, pluginConf of window.plugins
                    PluginUtils.deactivate pluginName
            return window.accounts
        if not accounts? or
        not Array.isArray accounts or
        not (accounts.some (a) -> return a.id is 'gmail-ID') or
        not  (accounts.some (a) -> return a.id is 'dovecot-ID')
            utils.dump accounts
            casper.test.done()
            casper.die("Fixtures not loaded, dying")
