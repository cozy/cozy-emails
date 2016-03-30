require '../styles/application.styl'

React = require 'react'
{div, section, main, p, span, a, i, strong, form, input, button} = React.DOM

# React components
Menu           = React.createFactory require './menu'
Modal          = React.createFactory require './modal'
ToastContainer = React.createFactory require './toast_container'
Tooltips       = React.createFactory require './tooltips-manager'
MessageList    = React.createFactory require './message-list'
Conversation   = React.createFactory require './conversation'

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
        console.log 'APPLICATION', @state
        div className: @props.className,

            div className: 'app',

                Menu()
                main
                    className: @props.layout

                    div
                        className: 'panels'
                        MessageList
                            ref         : 'messageList'
                            key         : 'messageList-' + @state.mailboxID
                            accountID   : @state.accountID
                            mailboxID   : @state.mailboxID

                        if @state.action is 'message.show'
                            Conversation
                                ref         : 'conversation'
                                key         : 'conversation-' + @state.messageID
                                messageID   : @state.messageID
                                mailboxID   : @state.mailboxID
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
