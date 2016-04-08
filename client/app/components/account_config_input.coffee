React = require 'react'

{div, label, input, textarea} = React.DOM
{ErrorLine, Dropdown} = require('./basic_components').factories

LinkedStateMixin = require 'react-addons-linked-state-mixin'


# Input used in the account configuration/creation form. An account input can
# display an error message below it.
module.exports = AccountInput = React.createClass
    displayName: 'AccountInput'

    mixins: [
        LinkedStateMixin
    ]

    # Update parent from child
    # but not child from child (infinite case)
    shouldComponentUpdate: (nextProps) ->
        not _.isEmpty _.difference nextProps, @props

    onChange: (event) ->
        @props.valueLink.requestChange event.target?.value

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
                        checkedLink: @props.valueLink.value
                        onChange: @onChange
                        type: type
                        onClick: @props.onClick
                else if type is 'textarea'
                    textarea
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        valueLink: @props.valueLink.value
                        onChange: @onChange
                        className: 'form-control'
                        placeholder: placeHolder
                        onBlur: @props.onBlur
                        onInput: @props.onInput
                else if type is 'dropdown'
                    Dropdown
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        valueLink: @props.valueLink.value
                        onChange: @onChange
                        options: @props.options
                        allowUndefined: @props.allowUndefined
                else
                    input
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        valueLink: @props.valueLink.value
                        onChange: @onChange
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
