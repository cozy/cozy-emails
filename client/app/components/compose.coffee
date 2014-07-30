{div, h3, a, i, textarea} = React.DOM
classer = React.addons.classSet

RouterMixin = require '../mixins/router'

module.exports = Compose = React.createClass
    displayName: 'Compose'

    mixins: [RouterMixin]

    render: ->

        expandUrl = @buildUrl
            direction: 'left'
            action: 'compose'
            parameter: null
            fullWidth: true

        closeUrl = @buildClosePanelUrl @props.layout

        div id: 'email-compose',
            h3 null,
                a href: expandUrl, className: 'expand',
                    i className: 'fa fa-angle-left'
                'Compose new email'
                a href: closeUrl, className: 'close-email',
                    i className:'fa fa-times'
            textarea defaultValue: 'Hello, how are you doing today?'
