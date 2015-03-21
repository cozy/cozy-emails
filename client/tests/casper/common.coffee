if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
fs = require 'fs'
utils   = require "utils"
system  = require "system"
x       = require('casper.js').selectXPath

dev = false

if utils.cmpVersion("1.1", phantom.casperVersion) > 0
    casper.die "You need at least CasperJS 1.1"

casper.cozy =
    startUrl: system.env.COZY_URL

casper.cozy.selectAccount = (account, box, cb) ->
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
            infos = casper.getElementInfo "[data-reactid='#{id}'].active [data-mailbox-id]"
            mailboxID = infos.attributes['data-mailbox-id']
            casper.waitForSelector ".message-list[data-mailbox-id='#{mailboxID}'] li.message", ->
                casper.waitWhileSelector ".list-footer .fa-spin", ->
                    if cb?
                        cb()
                , ->
                    casper.test.fail "#{account}/#{box} fetches forever"
            , ->
                casper.test.fail "No message in #{account}/#{box}"
        , ->
            casper.test.fail "Unable to go to mailbox #{box}"
    , ->
        casper.test.fail "Unable to go to account #{account}"

casper.cozy.selectMessage = (account, box, subject, messageID, cb) ->
    if typeof messageID is 'function'
        cb = messageID

    casper.cozy.selectAccount account, box, ->
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
                if not (typeof messageID is 'string')
                    infos = casper.getElementInfo subjectDone
                    messageID = infos.attributes['data-message-id']
                cb(subject, messageID)
            , ->
                casper.test.fail "Error displaying #{subject}"
        , ->
            casper.test.fail "No message matching #{subjectSel}"

if not casper.cozy.startUrl?
    casper.die "Please set the base URL into COZY_URL environment variable"

casper.getEngine = ->
    if typeof slimer is 'object' then 'slimer' else 'phantom'

exports.init = (casper) ->
    dev = casper.cli.options.dev?

    if dev
        casper.options.verbose = true
        casper.options.logLevel = 'debug'
    casper.options.waitTimeout = 20000
    casper.options.timeout = 200000
    casper.options.viewportSize = {width: 1024, height: 768}
    casper.on 'exit', (res) ->
        if res isnt 0 or dev
            outputDir = fs.workingDirectory + "/client/tests/output/"
            casper.capture(outputDir + "last.png")
            fs.write(outputDir + 'last.html', this.getHTML())
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
        utils.dump trace.slice 0, 5
    casper.on "load.finished", ->
        if casper.getTitle() isnt 'Cozy Emails'
            return
        if casper.getGlobal('__tests')?
            return
        accounts = casper.evaluate ->
            window.__tests = {}
            if window.cozyMails?
                # ensure locale is english
                window.cozyMails.setLocale 'en', true
                # hide toasts
                document.querySelector(".toasts-container").classList.add 'hidden'
                # deactivate all plugins
                PluginUtils = require '../utils/plugin_utils'
                for pluginName, pluginConf of window.plugins
                    PluginUtils.deactivate pluginName
                # default settings
                settings =
                    composeInHTML        : true
                    composeOnTop         : false
                    desktopNotifications : false
                    displayConversation  : true
                    displayPreview       : true
                    layoutStyle          : 'vertical'
                    listStyle            : 'default'
                    messageConfirmDelete : true
                    messageDisplayHTML   : true
                    messageDisplayImages : false
                cozyMails.setSetting settings
            return window.accounts
        if not accounts? or
        not Array.isArray accounts or
        not (accounts.some (a) -> return a.id is 'gmail-ID') or
        not  (accounts.some (a) -> return a.id is 'dovecot-ID')
            utils.dump accounts
            casper.test.done()
            casper.die("Fixtures not loaded, dying")
    casper.test.on 'fail', (failure) ->
        if failure? and typeof failure.message is 'string'
            outputDir = fs.workingDirectory + "/client/tests/output/"
            outputFile = failure.message.replace(/\W/gim, '')
            casper.capture "#{outputDir}#{outputFile}.png"
            fs.write("#{outputDir}#{outputFile}.html", casper.getHTML())
        else console.log failure
