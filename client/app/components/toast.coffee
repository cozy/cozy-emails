{div, button, span, strong} = React.DOM
SocketUtils = require '../utils/socketio_utils'


module.exports = React.createClass
    displayName: 'Toast'

    acknowledge: ->
        SocketUtils.acknowledgeTask @props.toast.get('id')

    render: ->
        toast = @props.toast.toJS()
        dismissible = if toast.finished then 'alert-dismissible' else ''
        percent = parseInt 100 * toast.done / toast.total

        div className: "alert toast alert-info #{dismissible}", role: "alert",
            div className:"progress",
                div 
                    className: 'progress-bar', 
                    role: 'progressbar', 
                    "style": width: "#{percent}%",
                    "aria-valuenow": toast.done, 
                    "aria-valuemin": 0, 
                    "aria-valuemax": toast.total,
                    "#{t "task " + toast.code, toast} : #{percent}%"
            if toast.finished
                button type: "button", className: "close", onClick: @acknowledge,
                    span 'aria-hidden': "true", "×"
                    span className: "sr-only", t "app alert close"
                    
