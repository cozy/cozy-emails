React = require 'react'

{div, input, button} = React.DOM

module.exports = React.createClass
    displayName: 'SearchInput'

    getInitialState: ->
        value: @props.value

    componentWillReceiveProps: (nextProps) ->
        @setState value: nextProps.value

    onChange: (event) ->
        @setState value: event.target.value

    onKeyUp: (event) ->
        @setState value: event.target.value
        if event.key is "Enter"
            event?.preventDefault()
            event?.stopPropagation()
            @props.onSubmit event.target.value
        @onResetClick() if event.key is "Escape"

    onCheckClick: (event) ->
        event?.preventDefault?()
        event?.stopPropagation?()
        @props.onSubmit @state.value

    onResetClick: (event) ->
        @setState value: ''
        event?.preventDefault?()
        event?.stopPropagation?()
        @props.onSubmit ''

    render: ->
        div role: 'search',
            input
                type:        'text'
                placeholder: @props.placeholder
                value:       @state.value
                onChange:    @onChange
                onKeyUp:     @onKeyUp
                name:        'searchterm'

            unless @state.value.length is 0
                div className: 'btn-group',
                    button
                        className: 'btn fa fa-check'
                        onClick: @onCheckClick

                    button
                        className: 'btn fa fa-close'
                        onClick: @onResetClick
