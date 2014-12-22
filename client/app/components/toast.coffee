{a, h4,  pre, div, button, span, strong, i} = React.DOM
SocketUtils     = require '../utils/socketio_utils'
AppDispatcher   = require '../app_dispatcher'
Modal           = require './modal'
StoreWatchMixin = require '../mixins/store_watch_mixin'
LayoutStore      = require '../stores/layout_store'
LayoutActionCreator = require '../actions/layout_action_creator'
{ActionTypes} = require '../constants/app_constants'
{CSSTransitionGroup} = React.addons

classer = React.addons.classSet

module.exports = Toast = React.createClass
    displayName: 'Toast'

    getInitialState: ->
        return modalErrors: false

    closeModal: ->
        @setState modalErrors: false

    showModal: (errors) ->
        @setState modalErrors: errors

    acknowledge: ->
        AppDispatcher.handleViewAction
            type: ActionTypes.RECEIVE_TASK_DELETE
            value: @props.toast.get('id')

    renderModal: ->
        title       = t 'modal please contribute'
        subtitle    = t 'modal please report'
        modalErrors = @state.modalErrors
        closeModal  = @closeModal
        closeLabel  = t 'app alert close'
        content = React.DOM.pre
            style: "max-height": "300px",
            "word-wrap": "normal",
                @state.modalErrors.join "\n\n"
        Modal {title, subtitle, content, closeModal, closeLabel}

    render: ->
        toast = @props.toast.toJS()
        hasErrors = toast.errors? and toast.errors.length
        classes = classer
            toast: true
            'alert-dismissible': toast.finished
            'alert-info': not hasErrors
            'alert-warning': hasErrors
        if toast.done? and toast.total?
            percent = parseInt(100 * toast.done / toast.total) + '%'
        if hasErrors
            showModal = @showModal.bind(this, toast.errors)

        div className: classes, role: "alert", key: @props.key,
            if @state.modalErrors
                renderModal()

            if percent?
                div className: "progress",
                    div
                        className: 'progress-bar',
                        style: width: percent
                    div
                        className: 'progress-bar-label start',
                        style: width: percent,
                        "#{t "task " + toast.code, toast} : #{percent}"
                    div
                        className: 'progress-bar-label end',
                        "#{t "task " + toast.code, toast} : #{percent}"

            if toast.message
                div className: "message", toast.message

            if toast.finished
                button
                    type: "button",
                    className: "close",
                    onClick: @acknowledge,
                        span 'aria-hidden': "true", "×"
                        span className: "sr-only", t "app alert close"

            if toast.actions?
                div className: 'toast-actions',
                    toast.actions.map (action, id) ->
                        button
                            className: "btn btn-default btn-xs",
                            type: "button",
                            key: id
                            onClick: action.onClick,
                            action.label


module.exports.Container = ToastContainer =  React.createClass
    displayName: 'ToastContainer'

    mixins: [
        StoreWatchMixin [LayoutStore]
    ]

    getStateFromStores: ->
        return {
            toasts: LayoutStore.getToasts()
            hidden: not LayoutStore.isShown()
        }

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->
        toasts = @state.toasts.map (toast, id) ->
            Toast {toast, key: id}
        .toVector().toJS()

        classes = classer
            'toasts-container': true
            'action-hidden': @state.hidden
            'has-toasts': toasts.length isnt 0

        div className: classes,
            CSSTransitionGroup transitionName: "toast",
                toasts
            div className: 'alert alert-success toast toasts-actions',
                span
                    className: "toast-action hide-action",
                    title: t 'toast hide'
                    onClick: @toggleHidden,
                        i className: 'fa fa-eye-slash'
                span
                    className: "toast-action show-action",
                    title: t 'toast show'
                    onClick: @toggleHidden,
                        i className: 'fa fa-eye'
                span
                    className: "toast-action close-action",
                    title: t 'toast close all'
                    onClick: @closeAll,
                        i className: 'fa fa-times'

    toggleHidden: ->
        if @state.hidden
            LayoutActionCreator.toastsShow()
        else
            LayoutActionCreator.toastsHide()

    closeAll: ->
        LayoutActionCreator.clearToasts()

    _clearToasts: ->
        setTimeout ->
            Array.prototype.forEach.call document.querySelectorAll('.toast-enter'), (e) ->
                e.classList.add 'hidden'
        , 10000

    componentDidMount: ->
        @_clearToasts()

    componentDidUpdate: ->
        @_clearToasts()
