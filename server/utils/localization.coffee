cozydb = require 'cozydb'
Polyglot = require 'node-polyglot'


waiting = []
translator = null

drainWaiting = (err, translator) ->
    callback err, translator for callback in waiting

exports.getPolyglot = (callback) ->
    if translator
        return callback null, translator
    else
        waiting.push callback

cozydb.api.getCozyLocale (err, locale) ->
    phrases = try require "../../client/app/locales/#{locale}"
    catch e then require "../../client/app/locales/en"
    try polyglot = new Polyglot {locale, phrases}
    catch e then return drainWaiting e, ->
    translator = polyglot.t.bind polyglot
    drainWaiting null, translator
