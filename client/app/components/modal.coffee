module.exports = Modal = React.createClass
    displayName: 'Modal'

    render: ->
        React.DOM.div
            className: "modal fade in",
            role: "dialog",
            style: display: 'block',
                React.DOM.div className: "modal-dialog",
                    React.DOM.div className: "modal-content",
                        if @props.title?
                            React.DOM.div className: "modal-header",
                                React.DOM.h4
                                    className: "modal-title",
                                    @props.title
                        React.DOM.div className: "modal-body",
                            if @props.subtitle?
                                React.DOM.span null, @props.subtitle
                            @props.content
                        if @props.closeLabel?
                            React.DOM.div className: "modal-footer",
                                React.DOM.button
                                    type: 'button',
                                    className: 'btn',
                                    onClick: @props.closeModal,
                                    @props.closeLabel

