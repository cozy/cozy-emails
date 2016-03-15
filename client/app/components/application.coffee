require '../styles/application.styl'

React = require 'react'

# React components
{div, section, main, p, span, a, i, strong, form, input, button} = React.DOM
Menu           = React.createFactory require './menu'
Modal          = React.createFactory require './modal'
Panel          = React.createFactory require './panel'
ToastContainer = React.createFactory require './toast_container'
Tooltips       = React.createFactory require './tooltips-manager'

# React Mixins
TooltipRefesherMixin = require '../mixins/tooltip_refresher_mixin'

Router = require '../mixins/router_mixin'
ApplicationGetters = require '../getters/application'

{MessageFilter} = require '../constants/app_constants'

###
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly

    About routing: it uses Backbone.Router as a source of truth for the layout.
    (based on:
        https://medium.com/react-tutorials/react-backbone-router-c00be0cf1592)
###

Application = React.createClass
    displayName: 'Application'

    mixins: [
        TooltipRefesherMixin
    ]

    getDefaultProps: ->
        ApplicationGetters.getProps 'application'

    componentWillMount: ->
        @setState ApplicationGetters.getState()

    componentWillReceiveProps: (nextProps={}) ->
        @setState ApplicationGetters.getState()
        return nextProps

    render: ->
        div className: @props.className,
            # Actual layout
            div className: 'app',
                # Menu is self-managed because this part of the layout
                # is always the same.
                Menu ref: 'menu', ApplicationGetters.getProps('menu')

                main
                    className: @props.layout

                    div
                        className: 'panels'

                        @getPanel 'message.list'
                        if @props.isMessage
                            @getPanel 'message.show'
                        else
                            section
                                'key'          : 'placeholder'
                                'aria-expanded': false

            # Display feedback
            Modal(modal) if @state.modal?

            ToastContainer()

            # Tooltips' content is declared once at the application level.
            # It's hidden so it doesn't break the layout. Other components
            # can then reference the tooltips by their ID to trigger them.
            Tooltips key: "tooltips"

    getPanel: (action) ->
        Panel ApplicationGetters.getProps('panel', {action})


module.exports = Application
