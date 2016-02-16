{div, button, span} = React.DOM

{Spinner} = require './basic_components'

module.exports = ComposeToolbox = React.createClass
    displayName: 'ComposeToolbox'

    render: ->
        labelSend = t 'compose action send'

        div className: 'composeToolbox',
            div className: 'btn-toolbar', role: 'toolbar',
                div className: '',
                    button
                        className: 'btn btn-cozy btn-send',
                        type: 'button',
                        onClick: @props.onSend,
                                span className: 'fa fa-send'
                            span null, labelSend
                    button
                        className: 'btn btn-cozy btn-save',
                        type: 'button', onClick: @props.onDraft,
                                span className: 'fa fa-save'
                            span null, t 'compose action draft'
                    if @props.canDelete
                        button
                            className: 'btn btn-cozy-non-default btn-delete',
                            type: 'button',
                            onClick: @props.onDelete,
                                span className: 'fa fa-trash-o'
                                span null, t 'compose action delete'
                    button
                        onClick: @props.onCancel
                        className: 'btn btn-cozy-non-default btn-cancel',
                        t 'app cancel'
