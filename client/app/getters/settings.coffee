
module.exports =
    get: (state, settingName) ->
        settings = state.get('settings')
        return settings.toObject() unless settingName
        return settings.get settingName
