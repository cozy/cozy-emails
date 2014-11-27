{a, h4,  pre, div, button, span, strong, i} = React.DOM
SocketUtils     = require '../utils/socketio_utils'
AppDispatcher   = require '../app_dispatcher'
Modal           = require './modal'
StoreWatchMixin = require '../mixins/store_watch_mixin'
LayoutStore      = require '../stores/layout_store'
LayoutActionCreator = require '../actions/layout_action_creator'
{ActionTypes} = require '../constants/app_constants'

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
            value: @props.toast.id

    render: ->
        toast = @props.toast
        hasErrors = toast.errors? and toast.errors.length
        classes = classer
            alert: true
            toast: true
            'alert-dismissible': toast.finished
            'alert-info': not hasErrors
            'alert-warning': hasErrors
        if toast.done? and toast.total?
            percent = parseInt(100 * toast.done / toast.total) + '%'
        if hasErrors
            showModal = @showModal.bind(this, toast.errors)
        if @state.modalErrors
            title       = t 'modal please contribute'
            subtitle    = t 'modal please report'
            modalErrors = @state.modalErrors
            closeModal  = @closeModal
            closeLabel  = t 'app alert close'
            content = React.DOM.pre
                style: "max-height": "300px",
                "word-wrap": "normal",
                    @state.modalErrors.join "\n\n"
            modal = Modal {title, subtitle, content, closeModal, closeLabel}

        div className: classes, role: "alert",
            if @state.modalErrors
                modal

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

            if hasErrors
                a onClick: showModal,
                    t 'there were errors', smart_count: toast.errors.length

    componentDidMount: ->
        @shouldAutoclose()

    componentDidUpdate: ->
        @shouldAutoclose()

    shouldAutoclose: ->
        hasErrors = @props.toast.errors? and @props.toast.errors.length
        if @props.toast.autoclose or (@props.toast.finished and not hasErrors)
            target = @getDOMNode()
            if not target.classList.contains 'autoclose'
                setTimeout ->
                    target.classList.add 'autoclose'
                , 1000
                setTimeout =>
                    @acknowledge()
                , 10000

module.exports.Container = ToastContainer =  React.createClass
    displayName: 'ToastContainer'

    mixins: [
        StoreWatchMixin [LayoutStore]
    ]

    getStateFromStores: ->
        return {
            toasts: LayoutStore.getTasks()
            hidden: not LayoutStore.isShown()
        }

    render: ->
        toasts = @state.toasts.toJS?() or @state.toasts

        classes = classer
            'toasts-container': true
            'action-hidden': @state.hidden
            'has-toasts': Object.keys(toasts).length isnt 0

        div className: classes,
            Toast {toast, key: id} for id, toast of toasts
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
        toasts = @state.toasts.toJS?() or @state.toasts
        close = (toast) ->
            if toast.type is NotifyType.SERVER
                SocketUtils.acknowledgeTask toast.id
            else
                AppDispatcher.handleViewAction
                    type: ActionTypes.RECEIVE_TASK_DELETE
                    value: toast.id
        close toast for id, toast of toasts
        @setState toasts: @state.toasts.clear()
