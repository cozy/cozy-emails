require = patchRequire global.require
utils   = require "/usr/local/lib/node_modules/casperjs/modules/utils.js"
system  = require "system"

dev = false

if utils.cmpVersion("1.1", phantom.casperVersion) > 0
    casper.die "You need at least CasperJS 1.1"

casper.cozy =
    startUrl: system.env.COZY_URL

if not casper.cozy.startUrl?
    casper.die "Please set the base URL into COZY_URL environment variable"

exports.init = (casper) ->
    dev = casper.cli.options.dev?

    if dev
        casper.options.verbose = true
        casper.options.logLevel = 'debug'
    casper.options.waitTimeout = 30000
    casper.options.timeout = 30000
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
