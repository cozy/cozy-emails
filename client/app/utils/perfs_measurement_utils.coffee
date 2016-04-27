Perf = require 'react-addons-perf'
ApiUtils = require '../utils/api_utils'

# expose an API for performance
# performance is not defined in phantomJS
module.exports.initPerformances = ->
    return unless __DEV__
    referencePoint = 0
    window.start = ->
        referencePoint = performance.now() if performance?.now?
        Perf.start()
    window.stop = ->
        console.log performance.now() - referencePoint if performance?.now?
        Perf.stop()
    window.printWasted = ->
        stop()
        Perf.printWasted()
    window.printInclusive = ->
        stop()
        Perf.printInclusive()
    window.printExclusive = ->
        stop()
        Perf.printExclusive()

    # starts perfs logging
    timing = window.performance?.timing
    now = Math.ceil window.performance?.now()
    if timing?
        message = "
            Response: #{timing.responseEnd - timing.navigationStart}ms
            Onload: #{timing.loadEventStart - timing.navigationStart}ms
            Page loaded: #{now}ms
        "
        ApiUtils.logInfo message
