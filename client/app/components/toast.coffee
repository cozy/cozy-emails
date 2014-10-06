{a, h4,  pre, div, button, span, strong} = React.DOM
SocketUtils = require '../utils/socketio_utils'


module.exports = React.createClass
    displayName: 'Toast'

    getInitialState: ->
        return modalErrors: false
    
    closeModal: ->
        @setState modalErrors: false

    showModal: (errors) ->
        @setState modalErrors: errors

    acknowledge: ->
        SocketUtils.acknowledgeTask @props.toast.get('id')

    renderErrorModal: ->
        console.log @state.modalErrors
        div className: "modal fade in", role: "dialog", style: display: 'block',
            div className: "modal-dialog",
                div className: "modal-content",
                    div className: "modal-header",
                        h4 className: "modal-title", t 'modal please contribute'
                    div className: "modal-body",
                        span null, t 'modal please report'
                        pre style: "max-height": "300px", "word-wrap": "normal", 
                            @state.modalErrors.join "\n\n"
                    div className: "modal-footer",
                        button type: 'button', className: 'btn', onClick: @closeModal,
                            t 'app alert close'

    render: ->
        toast = @props.toast.toJS()
        dismissible = if toast.finished then 'alert-dismissible' else ''
        percent = parseInt 100 * toast.done / toast.total
        showModal = @showModal.bind(this, toast.errors)
        type = if toast.errors.length then 'alert-warning'
        else 'alert-info'
        

        div className: "alert toast #{type} #{dismissible}", role: "alert",
            if @state.modalErrors
                @renderErrorModal() 

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

            if len = toast.errors.length
                a onClick: showModal, 
                    t 'there were errors', smart_count: len
                    
