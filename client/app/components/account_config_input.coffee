{div, label, input, textarea} = React.DOM
{ErrorLine} = require './basic_components'
classer = React.addons.classSet

RouterMixin = require '../mixins/router_mixin'


# Input used in the account configuration/creation form. An account input can
# display an error message below it.
module.exports = AccountInput = React.createClass
    displayName: 'AccountInput'

    mixins: [
        RouterMixin
        React.addons.LinkedStateMixin # two-way data binding
    ]


    getInitialState: ->
        return @props


    componentWillReceiveProps: (props) ->
        @setState props


    render: ->
        name = @props.name
        type = @props.type or 'text'
        errorField = @props.errorField or name
        mainClasses = @buildMainClasses errorField, name
        placeHolder = @buildPlaceHolder type, name

        div
            key: "account-input-#{name}"
            className: mainClasses,

            label
                htmlFor: "mailbox-#{name}"
                className: "col-sm-2 col-sm-offset-2 control-label",
                t "account #{name}"

            div className: 'col-sm-3',
                if type is 'checkbox'
                    input
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        checkedLink: @linkState('value').value
                        type: type
                        onClick: @props.onClick
                else if type is 'textarea'
                    textarea
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        valueLink: @linkState('value').value
                        className: 'form-control'
                        placeholder: placeHolder
                        onBlur: @onBlur
                        onInput: @props.onInput or null
                else
                    input
                        id: "mailbox-#{name}"
                        name: "mailbox-#{name}"
                        valueLink: @linkState('value').value
                        type: type
                        className: 'form-control'
                        placeholder: placeHolder
                        onBlur: @onBlur
                        onInput: @props.onInput or null

            @renderError(errorField, name)...


    onBlur: (event) ->
        @props.onBlur?(event)


    renderError: (errorField, name) ->
        result = []
        if Array.isArray errorField
            for error in errorField
                if @state.errors?[error]? and error is name
                    result.push ErrorLine text: @state.errors[error]
        else if @state.errors?[name]?
            result.push ErrorLine text: @state.errors[errorField]
        return result


    # Add error class if errors are listed.
    buildMainClasses: (fields, name) ->
        fields = [fields] if not Array.isArray fields
        errors = fields.some (field) => @state.errors[field]?
        mainClasses =  "form-group account-item-#{name} "
        mainClasses = "#{mainClasses} has-error " if errors
        mainClasses = "#{mainClasses} #{@props.className} " if @props.className
        return mainClasses


    # Build input placeholder depending on given type (build right translation
    # key and run translation process on it).
    buildPlaceHolder: (type, name) ->
        placeHolder = null
        if type in ['text', 'email'] or name is 'signature'
            placeHolder = t "account #{name} short"
        return placeHolder

