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

        span className: 'menu-item trigger-refresh-action',

            # Show the button to trigger a refresh if no refresh is occuring.
            if not @state.isRefreshing
                button
                    className: ''
                    type: 'button'
                    disabled: null
                    title: t("menu refresh label")
                    onClick: @refresh,
                        span className: 'fa fa-refresh'
                        span null, t("menu refresh label")


            # Or an indicator of the progress if a refresh is occurring.
            else
                [
                        Spinner key: 'spinner', white: true
                    ,
                        t("menu refreshing")
                ]


    # Trigger the refresh action.
    refresh: (event) ->
        @setState isRefreshing: true
        event.preventDefault()
        LayoutActionCreator.refreshMessages =>
            @setState isRefreshing: false
