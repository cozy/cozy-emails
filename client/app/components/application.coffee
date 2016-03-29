require '../styles/application.styl'

React = require 'react'
{div, section, main, p, span, a, i, strong, form, input, button} = React.DOM

# React components
Menu           = React.createFactory require './menu'
Modal          = React.createFactory require './modal'
Panel          = React.createFactory require './panel'
ToastContainer = React.createFactory require './toast_container'
Tooltips       = React.createFactory require './tooltips-manager'

# React Mixins
MessageStore         = require '../stores/message_store'
RouterStore          = require '../stores/router_store'
SettingsStore        = require '../stores/settings_store'
StoreWatchMixin      = require '../mixins/store_watch_mixin'
TooltipRefesherMixin = require '../mixins/tooltip_refresher_mixin'

ApplicationGetters = require '../getters/application'

###
    This component is the root of the React tree.

    It has two functions:
        - building the layout based on the router
        - listening for changes in  the model (Flux stores)
          and re-render accordingly
###

Application = React.createClass
    displayName: 'Application'

    mixins: [
        TooltipRefesherMixin
        StoreWatchMixin [SettingsStore, RouterStore, MessageStore]
    ]

    getDefaultProps: ->
        ApplicationGetters.getProps 'application'

    getInitialState: ->
        ApplicationGetters.getState()

    componentWillReceiveProps: (nextProps={}) ->
        @setState ApplicationGetters.getState()
        nextProps

    render: ->
        div className: @props.className,

            div className: 'app',

                Menu()

                main
                    className: @props.layout

                    div
                        className: 'panels'

                        Panel messages: @state.messages, action: 'message.list'
                        if @state.action is 'message.show'
                            Panel messages: @state.messages, action: 'message.show'
                        else
                            section
                                'key'          : 'placeholder'
                                'aria-expanded': false

            # Display feedback
            Modal @state.modal if @state.modal?

            ToastContainer()

            # Tooltips' content is declared once at the application level.
            # It's hidden so it doesn't break the layout. Other components
            # can then reference the tooltips by their ID to trigger them.
            Tooltips key: "tooltips"

module.exports = Application
