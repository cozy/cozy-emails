{span, button, img} = React.DOM

LayoutActionCreator  = require '../actions/layout_action_creator'

{Spinner} = require './basic_components'

# This component is the refresh button, which is replaced by a progress
# indicator if a refresh is running.
module.exports = React.createClass
    displayName: 'RefreshIndicator'

    protoTypes:
        refreshes: React.PropTypes.object.isRequired
        selectedAccount: React.PropTypes.object.isRequired
        selectedMailboxID: React.PropTypes.string

    # Define a flag to know if a refresh is occurring or not.
    getInitialState: ->
        isRefreshing: false


    render: ->
        # Show the button to trigger a refresh if no refresh is occuring.
        if not @state.isRefreshing
            button
                className: 'btn'
                type: 'button'
                role: 'menuitem'
                disabled: null
                title: t("menu refresh label")
                onClick: @refresh,
                    span className: 'fa fa-refresh'


        # Or an indicator of the progress if a refresh is occurring.
        else
            button
                className: 'btn'
                type: 'button'
                role: 'menuitem'
                disabled: true
                title: t("menu refreshing")
                onClick: @refresh,
                    span className: 'fa fa-refresh fa-spin'


    # Trigger the refresh action.
    refresh: (event) ->
        @setState isRefreshing: true
        event.preventDefault()
        LayoutActionCreator.refreshMessages =>
            @setState isRefreshing: false
