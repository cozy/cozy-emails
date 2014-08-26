React = require 'react/addons'
moment = require 'moment'

{div, ul, li, span, i, p, h3, a} = React.DOM
classer = React.addons.classSet

module.exports = EmailThread = React.createClass
    displayName: 'Email'

    getInitialState: -> active: false

    render: ->
        clickHandler = if @props.isLast then null else @onClick

        classes = classer
            email: true
            active: @state.active

        today = moment()
        date = moment @props.email.get 'createdAt'
        if date.isBefore today, 'year'
            formatter = 'DD/MM/YYYY'
        else if date.isBefore today, 'day'
            formatter = 'DD MMMM'
        else
            formatter = 'hh:mm'

        li className: classes, key: @props.key, onClick: clickHandler,
            div className: 'email-header',
                i className: 'fa fa-user'
                div className: 'email-participants',
                    span  className: 'sender', @props.email.get 'from'
                    span className: 'receivers', t "mail receivers", {dest: @props.email.to}
                span className: 'email-hour', date.format formatter
            div className: 'email-preview',
                p null, @props.email.get 'text'
            div className: 'email-content', @props.email.get 'text'
            div className: 'clearfix'

    onClick: (args) ->
        @setState active: not @state.active
