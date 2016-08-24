
reduxStore = require '../reducers/_store'
pure = require '../puregetters/settings'

module.exports =

    get: (settingName = null) ->
        pure.get reduxStore.getState(), settingName
