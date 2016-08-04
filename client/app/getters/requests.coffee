reduxStore = require '../reducers/_store'
pure = require '../puregetters/requests'

module.exports =
    isAccountCreationBusy: ->
        pure.isAccountCreationBusy reduxStore.getState()

    isAccountDiscoverable: ->
        pure.isAccountDiscoverable reduxStore.getState()

    getAccountCreationAlert: ->
        pure.getAccountCreationAlert reduxStore.getState()

    isAccountOAuth: ->
        pure.isAccountOAuth reduxStore.getState()

    getAccountCreationDiscover: ->
        pure.getAccountCreationDiscover reduxStore.getState()

    getAccountCreationSuccess: ->
        pure.getAccountCreationSuccess reduxStore.getState()
