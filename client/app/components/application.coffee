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
SettingsStore       = require '../stores/settings_store'
AccountStore        = require '../stores/account_store'
MessageStore        = require '../stores/message_store'
LayoutStore         = require '../stores/layout_store'
StoreWatchMixin         = require '../mixins/store_watch_mixin'
TooltipRefesherMixin = require '../mixins/tooltip_refresher_mixin'

ApplicationGetters = require '../getters/application'

{MessageFilter} = require '../constants/app_constants'

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
        StoreWatchMixin [SettingsStore, AccountStore, MessageStore, LayoutStore]
    ]

    getDefaultProps: ->
        ApplicationGetters.getProps 'application'

    getInitialState: ->
        ApplicationGetters.getState()

    componentWillReceiveProps: (nextProps={}) ->
        @setState ApplicationGetters.getState()
        nextProps

    render: ->
        # FIXME : n'est pas reloadé après chargement du contenu
        # le state est mal calculé
        # Il manque la liste des messages
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
                        if @state.messageID?
                            @getPanel 'message.show'
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

    getPanel: (action) ->
        Panel ApplicationGetters.getProps('panel', {action})


module.exports = Application
