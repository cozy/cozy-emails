React = require 'react/addons'
{div, h3, a, i, textarea} = React.DOM
classer = React.addons.classSet

RouterMixin = require '../mixins/RouterMixin'

module.exports = Compose = React.createClass
    displayName: 'Compose'

    mixins: [RouterMixin]

    render: ->

        expandUrl = @buildUrl
            direction: 'left'
            action: 'compose'
            fullWidth: true

        collapseUrl = @buildUrl
            leftPanel:
                action: 'mailbox.emails'
                parameters: @props.selectedMailbox.id
            rightPanel:
                action: 'compose'

        closeUrl = @buildClosePanelUrl @props.layout

        div id: 'email-compose',
            h3 null,
                a href: closeUrl, className: 'close-email hidden-xs hidden-sm',
                    i className:'fa fa-times'
                'Compose new email'
                if @props.layout isnt 'full'
                    a href: expandUrl, className: 'expand hidden-xs hidden-sm',
                        i className: 'fa fa-arrows-h'
                else
                    a href: collapseUrl, className: 'close-email pull-right',
                        i className:'fa fa-compress'
            textarea defaultValue: 'Hello, how are you doing today?'
