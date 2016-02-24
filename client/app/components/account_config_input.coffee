React = require 'react'

{div, label, input, textarea} = React.DOM
{ErrorLine, Dropdown} = require('./basic_components').factories

RouterMixin      = require '../mixins/router_mixin'
LinkedStateMixin = require 'react-addons-linked-state-mixin'


# Input used in the account configuration/creation form. An account input can
# display an error message below it.
module.exports = AccountInput = React.createClass
    displayName: 'AccountInput'

    mixins: [
        RouterMixin
        LinkedStateMixin
    ]

    propTypes:
        name: React.PropTypes.string.isRequired
        error: React.PropTypes.string

        className: React.PropTypes.string
        onClick: React.PropTypes.func
        onInput: React.PropTypes.func
        onBlur: React.PropTypes.func
        type: React.PropTypes.oneOf [
            'checkbox', 'textarea', 'email', 'text', 'password'
        ]
        valueLink: React.PropTypes.shape
            value: React.PropTypes.any
            requestChange: React.PropTypes.func.isRequired
        options: (props) ->
            if props.type is 'dropdown'
                React.PropTypes.object.isRequired.apply this, arguments


    getDefaultProps: -> type: 'text'

    render: ->
        name = @props.name
        type = @props.type or 'text'
        placeHolder = @buildPlaceHolder type, name

        div
            key: "account-input-#{name}"
            className: @buildMainClasses(name),

            label
                htmlFor: "mailbox-#{name}"
                className: "col-sm-2 col-sm-offset-2 control-label",
                t "account #{name}"

            div className: 'col-sm-3',
                if type is 'checkbox'
                    input
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        checkedLink: @props.valueLink
                        type: type
                        onClick: @props.onClick
                else if type is 'textarea'
                    textarea
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        valueLink: @props.valueLink
                        className: 'form-control'
                        placeholder: placeHolder
                        onBlur: @props.onBlur
                        onInput: @props.onInput
                else if type is 'dropdown'
                    Dropdown
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        valueLink: @props.valueLink
                        options: @props.options
                        allowUndefined: @props.allowUndefined
                else
                    input
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        valueLink: @props.valueLink
                        type: type
                        className: 'form-control'
                        placeholder: placeHolder
                        onBlur: @props.onBlur
                        onInput: @props.onInput

            if @props.error
                ErrorLine text: @props.error


    # Add error class if errors are listed.
    buildMainClasses: (name) ->
        mainClasses =  "form-group account-item-#{name} "
        mainClasses = "#{mainClasses} has-error " if @props.error
        mainClasses = "#{mainClasses} #{@props.className} " if @props.className
        return mainClasses


    # Build input placeholder depending on given type (build right translation
    # key and run translation process on it).
    buildPlaceHolder: (type, name) ->
        placeHolder = null
        if type in ['text', 'email'] or name is 'signature'
            placeHolder = t "account #{name} short"
        return placeHolder
