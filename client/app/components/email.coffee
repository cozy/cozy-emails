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

        li className: classes, key: @props.key, onClick: clickHandler,
            div className: 'email-header',
                i className: 'fa fa-user'
                div className: 'email-participants',
                    span  className: 'sender', @props.email.from
                    span className: 'receivers', 'À ' + @props.email.to
                span className: 'email-hour', @props.email.date
            div className: 'email-preview',
                p null, @props.email.text
            div className: 'email-content', @props.email.text
            div className: 'clearfix'

    onClick: (args) ->
        @setState active: not @state.active
