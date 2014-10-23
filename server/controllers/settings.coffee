Settings = require '../models/settings'

module.exports =

	change: (req, res, next) ->
		Settings.getInstance()
		.then (settings) ->
			for key, value of req.body
				settings[key] = value

			settings.savePromised()
		.then (updated) -> res.send updated
		.catch next