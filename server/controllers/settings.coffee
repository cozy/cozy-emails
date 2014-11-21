Settings = require '../models/settings'

module.exports =

    get: (req, res, next) ->
        Settings.get (err, settings) ->
            return next err if err
            res.send settings

    change: (req, res, next) ->
        Settings.set req.body, (err, updated) ->
            return next err if err
            res.send updated