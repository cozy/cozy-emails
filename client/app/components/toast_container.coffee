_          = require 'underscore'
classNames = require 'classnames'
React      = require 'react'

{div} = React.DOM

Animate             = React.createFactory require 'rc-animate'
Toast               = React.createFactory require './toast'

LayoutGetter        = require '../getters/layout'
RouterGetter        = require '../getters/router'
LayoutActionCreator = require '../actions/layout_action_creator'


# Main container in wich toasts are displayed.
module.exports = ToastContainer = React.createClass
    displayName: 'ToastContainer'

    # FIXME : use getters instead
    # such as : ToastContainer.getState()
    getInitialState: ->
        @getStateFromStores()

    # FIXME : use getters instead
    # such as : ToastContainer.getState()
    componentWillReceiveProps: (nextProps={}) ->
        @setState @getStateFromStores()
        nextProps

    getStateFromStores: ->
        return {
            toasts: RouterGetter.getToasts()
            hidden: LayoutGetter.isToastHidden()
        }


    shouldComponentUpdate: (nextProps, nextState) ->
        isNextState = _.isEqual nextState, @state
        isNextProps = _.isEqual nextProps, @props
        return not(isNextState and isNextProps)


    render: ->
        toasts = @state.toasts
        .mapEntries ([id, toast]) ->
            ["toast-#{id}", Toast {key: id, toast}]
        .toArray()

        div
            className: classNames
                'toasts-container': true
                'has-toasts': toasts.size isnt 0
            'aria-hidden': @state.hidden,
            
            Animate transitionName: 'toast', toasts


    toggleHidden: ->
        if @state.hidden
            LayoutActionCreator.toastsShow()
        else
            LayoutActionCreator.toastsHide()

    # Clear hidden toasts on a regular basis.
    _clearToasts: ->
        setTimeout ->
            toasts = document.querySelectorAll('.toast-enter')
            Array.prototype.forEach.call toasts, (e) ->
                e.classList.add 'hidden'
        , 10000


    closeAll: ->
        LayoutActionCreator.clearToasts()


    componentDidMount: ->
        @_clearToasts()


    componentDidUpdate: ->
        @_clearToasts()
