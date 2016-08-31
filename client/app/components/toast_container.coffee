_          = require 'underscore'
classNames = require 'classnames'
React      = require 'react'

{div} = React.DOM

Animate             = React.createFactory require 'rc-animate'
Toast               = React.createFactory require './toast'

# Main container in wich toasts are displayed.
module.exports = ToastContainer = React.createClass
    displayName: 'ToastContainer'

    shouldComponentUpdate: (nextProps) ->
        return not _.isEqual nextProps, @props

    render: ->
        div
            className: classNames
                'toasts-container': true
                'has-toasts': @props.toasts.size isnt 0
            'aria-hidden': @props.hidden,

            Animate transitionName: 'toast',
                @props.toasts.map (toast) =>
                    Toast
                        key: toast.get('id')
                        toast: toast
                        displayModal: @props.displayModal
                        doDeleteToast: @props.doDeleteToast
                .toArray()


    toggleHidden: ->
        if @props.hidden
            @props.toastsShow()
        else
            @props.toastsHide()

    # Clear hidden toasts on a regular basis.
    _clearToasts: ->
        setTimeout ->
            toasts = document.querySelectorAll('.toast-enter')
            Array.prototype.forEach.call toasts, (e) ->
                e.classList.add 'hidden'
        , 10000


    closeAll: ->
        @props.clearToasts()


    componentDidMount: ->
        @_clearToasts()


    componentDidUpdate: ->
        @_clearToasts()
