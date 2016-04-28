_ = require 'underscore'

RouterActionCreator = require '../actions/router_action_creator'
{MessageFlags} = require '../constants/app_constants'

module.exports = StoreWatchMixin = (stores) ->

    componentDidMount: ->
        # Update state
        # when linked store emit changes.
        stores.forEach (store) =>
            store.addListener 'change', @_setStateFromStores

    componentWillUnmount: ->
        # Mark message as read
        if @state?.message?.size
            messageID = @state.message.get 'id'
            RouterActionCreator.mark {messageID}, MessageFlags.SEEN

        # Stop listening to the linked stores
        # when the component is unmounted.
        stores.forEach (store) =>
            store.removeListener 'change', @_setStateFromStores

    getInitialState: ->
        # Build initial state
        # from store values.
        @getStateFromStores @props

    componentWillReceiveProps: (nextProps={}) ->
        @setState @getStateFromStores nextProps
        nextProps

    _setStateFromStores: ->
        return unless @isMounted()
        nextState = @getInitialState()
        changes = _difference nextState, @state
        unless _.isEmpty changes
            # Update state with store values
            # console.log 'change', changes
            @setState nextState

_difference = (obj0, obj1) ->
    result = {}
    _.filter obj0, (value, key) ->
        unless value is obj1[key]
            result[key] = value
    result
