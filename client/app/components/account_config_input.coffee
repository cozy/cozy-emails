React = require 'react'

{div, label, input, textarea} = React.DOM
{ErrorLine, Dropdown} = require('./basic_components').factories

LinkedStateMixin = require 'react-addons-linked-state-mixin'

# Input used in the account configuration/creation form. An account input can
# display an error message below it.
module.exports = AccountInput = React.createClass
    displayName: 'AccountInput'

    # Update parent from child
    # or child from parent
    shouldComponentUpdate: (nextProps) ->
        # Check props update
        # excluding valueLink (special case)
        nextValue = nextProps.valueLink.value
        unless (hasChanged = nextValue isnt @props.valueLink.value)
            _props = _.omit @props, 'valueLink'
            _nextProps = _.omit nextProps, 'valueLink'
            hasChanged = not _.isEqual _props, _nextProps
        hasChanged

    onChange: (event) ->
        type = event.target.getAttribute 'type'
        value = event.target.value
        value = event.target.checked if type in ['checkbox', 'radio']

        @props.valueLink.requestChange value

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
                        checked: @props.valueLink.value
                        onChange: @onChange
                        type: type
                else if type is 'textarea'
                    textarea
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        value: @props.valueLink.value
                        onChange: @onChange
                        className: 'form-control'
                        placeholder: placeHolder
                else if type is 'dropdown'
                    Dropdown
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        value: @props.valueLink.value
                        onChange: @onChange
                        options: @props.options
                        allowUndefined: @props.allowUndefined
                else
                    input
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        value: @props.valueLink.value
                        onChange: @onChange
                        type: type
                        className: 'form-control'
                        placeholder: placeHolder

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
