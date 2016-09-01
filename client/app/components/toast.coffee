React      = require 'react'
classNames = require 'classnames'

{pre, div, button, span} = React.DOM


{AlertLevel} = require '../constants/app_constants'


# The toast is a notification widget displayed on the top right of the screen.
# It stays temporarly and is dismissed just after a few seconds.
# This Component can be used to display informative modals.
module.exports = Toast = React.createClass

    displayName: 'Toast'


    # A toast is composed of several elements:
    # * message, the displayed text.
    # * close button, to dismiss the toast before the timeout ends.
    # * action button, to enable actions like undoing
    #
    # If there are errors attached to the toast, a modal is displayed instead
    # of a toast. The modal give stacktrace so the user can communicate it
    # to the Cozy team.
    render: ->
        toast     = @props.toast.toJS()
        hasErrors = toast.errors?.length
        classes   = classNames
            toast: true
            'alert-dismissible': toast.finished
            'toast-error': toast.level is AlertLevel.ERROR

        div className: classes, role: "alert", key: @props.key,
            if toast.message
                div className: "message", toast.message

            if toast.finished or hasErrors
                button
                    type: "button",
                    className: "close",
                    onClick: @acknowledge,
                        span 'aria-hidden': "true", "×"
                        span className: "sr-only", t "app alert close"

            if toast.actions?
                className = "btn btn-cancel btn-cozy-non-default btn-xs"
                div className: 'toast-actions',
                    toast.actions.map (action, id) ->
                        button
                            className: className,
                            type: "button",
                            key: id
                            onClick: action.onClick,
                            action.label

            if hasErrors
                className = "btn btn-cancel btn-cozy-non-default btn-xs"
                div className: 'toast-actions',
                    button
                        className: className,
                        type: "button",
                        key: 'errors'
                        onClick: @onModalShowClicked,
                        t 'there were errors', smart_count: toast.errors.length


    onModalShowClicked: ->
        errorText = JSON.stringify(@props.toast.get('errors')[0])

        @props.displayModal
            title       : t 'modal please contribute'
            subtitle    : t 'modal please report'
            closeLabel  : t 'app alert close'
            content     :
                pre style: "max-height": "300px", "word-wrap": "normal",
                    errorText


    acknowledge: ->
        @props.doDeleteToast @props.toast.get 'id'
