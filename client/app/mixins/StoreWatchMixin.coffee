module.exports = StoreWatchMixin = (stores) ->

    return {
        componentDidMount: ->
            stores.forEach (store) => store.on 'change', @_setStateFromStores

        componentWillUnmount: ->
            stores.forEach (store) => store.removeListener 'change', @_setStateFromStores

        getInitialState: -> return @getStateFromStores()

        _setStateFromStores: -> @setState @getStateFromStores()
    }