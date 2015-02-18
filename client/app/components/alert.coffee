{div, button, span, strong} = React.DOM
{AlertLevel}     = require '../constants/app_constants'
LayoutActionCreator = require '../actions/layout_action_creator'

module.exports = React.createClass
    displayName: 'Alert'

    render: ->

        alert = @props.alert
        if alert.level?
            levels = {}
            levels[AlertLevel.SUCCESS] = 'alert-success'
            levels[AlertLevel.INFO]    = 'alert-info'
            levels[AlertLevel.WARNING] = 'alert-warning'
            levels[AlertLevel.ERROR]   = 'alert-danger'

        div className: 'row row-alert',
            if alert.level?
                div
                    ref: 'alert'
                    className: "alert #{levels[alert.level]} alert-dismissible",
                    role: "alert",
                        button
                            type: "button",
                            className: "close",
                            onClick: @hide,
                                span 'aria-hidden': "true", "×"
                                span className: "sr-only", t "app alert close"
                        strong null, alert.message

    hide: ->
        LayoutActionCreator.alertHide()

    autohide: ->
        if false and @props.alert.level is AlertLevel.SUCCESS
            setTimeout =>
                @refs.alert.getDOMNode().classList.add 'autoclose'
            , 1000
            setTimeout @hide, 10000

    componentDidMount: ->
        @autohide()

    componentDidUpdate: ->
        @autohide()
