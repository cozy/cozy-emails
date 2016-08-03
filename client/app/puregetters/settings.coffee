
module.exports =
    get: (state, settingName) ->
        settings = state.settings.settings
        return settings.toObject() unless settingName
        return settings.get settingName
