{div, button, span} = React.DOM

{Spinner} = require './basic_components'

module.exports = ComposeToolbox = React.createClass
    displayName: 'ComposeToolbox'

    getInitialState: ->
        action: null

    getLabel: ->
        className = if @state.action is 'send' then 'sending' else 'send'
        t 'compose action ' + className

    save: ->
        @triggerAction 'save'

    send: ->
        @triggerAction 'send'

    delete: ->
        @triggerAction 'delete'

    cancel: ->
        @triggerAction 'cancel'

    triggerAction: (type) ->
        @setState action : type
        if (callback = @props[type]) and _.isFunction callback
            callback()

    render: ->
        div className: 'composeToolbox',
            div className: 'btn-toolbar', role: 'toolbar',
                div className: '',
                    button
                        className: 'btn btn-cozy btn-send',
                        type: 'button',
                        disable: if @state.action is 'send' then true else null
                        onClick: @send,
                            if @state.action is 'send'
                                span null, Spinner(color: 'white')
                            else
                                span className: 'fa fa-send'
                            span null, @getLabel()
                    button
                        className: 'btn btn-cozy btn-save',
                        disable: if @state.action is 'save' then true else null
                        type: 'button', onClick: @save,
                            if @state.action is 'save'
                                span null, Spinner(color: 'white')
                            else
                                span className: 'fa fa-save'
                            span null, t 'compose action draft'
                    if @props.canDelete
                        button
                            className: 'btn btn-cozy-non-default btn-delete',
                            type: 'button',
                            onClick: @delete,
                                span className: 'fa fa-trash-o'
                                span null, t 'compose action delete'
                    button
                        onClick: @props.cancel
                        className: 'btn btn-cozy-non-default btn-cancel',
                        t 'app cancel'
