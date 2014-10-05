require = patchRequire global.require
utils = require "/usr/local/lib/node_modules/casperjs/modules/utils.js"

dev = false

exports.init = (casper) ->
    if dev
        casper.options.verbose = true
        casper.options.logLevel = 'debug'
    casper.on 'exit', ->
        if dev
            casper.capture("last.png")
            require('fs').write('last.html', this.getHTML())
    casper.on "remote.message", (msg) ->
        if dev
            casper.echo "Message: " + msg, "INFO"
    casper.on "page.error", (msg, trace) ->
        casper.echo "Error: " + msg, "ERROR"
        utils.dump trace.slice 0, 2


