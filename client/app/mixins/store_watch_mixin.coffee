_ = require 'underscore'

module.exports = StoreWatchMixin = (stores) ->

    # Update state when linked store emit changes.
    componentDidMount: ->
        stores.forEach (store) =>
            store.addListener 'change', @_setStateFromStores


    # Stop listening to the linked stores when the component is unmounted.
    componentWillUnmount: ->
        stores.forEach (store) =>
            store.removeListener 'change', @_setStateFromStores

    # Build initial state from store values.
    getInitialState: ->
        return @getStateFromStores()


    # Update state with store values.
    _setStateFromStores: ->
        return unless @isMounted()

        _difference = (obj0, obj1) ->
            result = {}
            _.filter obj0, (value, key) ->
                unless value is obj1[key]
                    result[key] = value
            result

        nextState = @getStateFromStores()
        changes = _difference nextState, @state
        unless _.isEmpty changes
            @setState nextState
