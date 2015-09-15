

module.exports = Modal = React.createClass
    displayName: 'Modal'

    render: ->
        contentClass = ''
        contentClass = 'no-content' if not @props.content
        React.DOM.div
            className: "modal fade in",
            role: "dialog",
            style: display: 'block',
                React.DOM.div className: "modal-dialog",
                    React.DOM.div className: "modal-content",
                        if @props.title?
                            React.DOM.div className: "modal-header",
                                if @props.closeLabel?
                                    React.DOM.button
                                        type: 'button',
                                        className: 'close',
                                        onClick: @props.closeModal,
                                            React.DOM.i className: 'fa fa-times'
                                React.DOM.h4
                                    className: "modal-title",
                                    @props.title
                        React.DOM.div className: "modal-body #{contentClass}",
                            if @props.subtitle?
                                React.DOM.span null, @props.subtitle
                            if @props.content?
                                React.DOM.div ref: 'content',
                                    @props.content
                        React.DOM.div className: "modal-footer",
                            if @props.allowCopy
                                React.DOM.button
                                    type: 'button',
                                    className: 'btn btn-cozy modal-copy',
                                    onClick: @copyContent
                                    t 'modal copy content'
                            if @props.actionLabel? and @props.action
                                React.DOM.button
                                    type: 'button',
                                    className: 'btn btn-cozy modal-action',
                                    onClick: @props.action,
                                    @props.actionLabel
                            if @props.closeLabel?
                                React.DOM.button
                                    type: 'button',
                                    className: 'btn btn-cozy-non-default modal-close',
                                    onClick: @props.closeModal,
                                    @props.closeLabel


    copyContent: ->
        sel = window.getSelection()
        sel.removeAllRanges() if sel.rangeCount > 0

        range = document.createRange()
        range.selectNode @refs.content?.getDOMNode()
        sel.addRange range

        document.execCommand 'copy'

