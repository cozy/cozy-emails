Settings = require '../models/settings'

module.exports =

    change: (req, res, next) ->
        Settings.getInstance (err, settings) ->
            return next err if err

            for key, value of req.body
                settings[key] = value

            settings.save (err) ->
                res.send settings