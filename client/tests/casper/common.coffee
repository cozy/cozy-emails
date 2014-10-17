require = patchRequire global.require
utils = require "/usr/local/lib/node_modules/casperjs/modules/utils.js"

dev = false

exports.init = (casper) ->
    dev = casper.cli.options.dev?

    if dev
        casper.options.verbose = true
        casper.options.logLevel = 'debug'
        casper.options.waitTimeout = 30000
        casper.options.timeout = 30000
    casper.options.viewportSize = {width: 1024, height: 768}
    casper.on 'exit', ->
        if dev
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
        # ensure locale is english
        casper.evaluate ->
            window.cozyMails.setLocale 'en', true
            document.querySelector(".toasts-container").classList.add 'hidden'


