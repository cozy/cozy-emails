{div, button, span, strong} = React.DOM
{AlertLevel}     = require '../constants/app_constants'

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

        div className: 'row',
            if alert.level?
                div className: "alert #{levels[alert.level]} alert-dismissible", role: "alert",
                    button type: "button", className: "close", "data-dismiss": "alert",
                        span 'aria-hidden': "true", "×"
                        span className: "sr-only", t "app alert close"
                    strong> null, alert.message
