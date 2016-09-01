React = require 'react'

{div, span, h4, i, button} = React.DOM


module.exports = Modal = React.createFactory React.createClass
    displayName: 'Modal'

    render: ->
        contentClass = ''
        contentClass = 'no-content' if not @props.content
        div
            className: "modal fade in",
            role: "dialog",
            style: display: 'block',
                div className: "modal-dialog",
                    div className: "modal-content",
                        if @props.title?
                            div className: "modal-header",
                                if @props.closeLabel?
                                    button
                                        type: 'button',
                                        className: 'close',
                                        onClick: @props.closeModal,
                                            i className: 'fa fa-times'
                                h4
                                    className: "modal-title",
                                    @props.title
                        div className: "modal-body #{contentClass}",
                            if @props.subtitle?
                                span null, @props.subtitle
                            if @props.content?
                                div ref: 'content',
                                    @props.content
                        div className: "modal-footer",
                            if @props.allowCopy
                                button
                                    type: 'button',
                                    className: 'btn btn-cozy modal-copy',
                                    onClick: @copyContent
                                    t 'modal copy content'
                            if @props.actionLabel? and @props.action
                                button
                                    type: 'button',
                                    className: 'btn btn-cozy modal-action',
                                    onClick: @doAction,
                                    @props.actionLabel
                            if @props.closeLabel?
                                button
                                    type: 'button',
                                    className: 'btn btn-cozy-non-default modal-close',
                                    onClick: @props.closeModal,
                                    @props.closeLabel

    doAction: ->
        @props.action(@props.closeModal)

    copyContent: ->
        sel = window.getSelection()
        sel.removeAllRanges() if sel.rangeCount > 0

        range = document.createRange()
        range.selectNode @refs.content?
        sel.addRange range

        document.execCommand 'copy'
