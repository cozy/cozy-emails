module.exports = StoreWatchMixin = (stores) ->


    # Update state when linked store emit changes.
    componentDidMount: ->
        stores.forEach (store) =>
            store.on 'change', @_setStateFromStores


    # Stop listening to the linked stores when the component is unmounted.
    componentWillUnmount: ->
        stores.forEach (store) =>
            store.removeListener 'change', @_setStateFromStores


    # Build initial state from store values.
    getInitialState: ->
        return @getStateFromStores()


    # Update state with store values.
    _setStateFromStores: ->
        if @isMounted()
            @setState @getStateFromStores()

