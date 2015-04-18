{
    div, p, h3, h4, form, label, input, button, ul, li, a, span, i,
    fieldset, legend
} = React.DOM
classer = React.addons.classSet

MailboxList          = require './mailbox-list'
AccountActionCreator = require '../actions/account_action_creator'
RouterMixin = require '../mixins/router_mixin'
LAC  = require '../actions/layout_action_creator'
classer = React.addons.classSet


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
        hasError = (fields) =>
            if not Array.isArray fields
                fields = [ fields ]
            errors = fields.some (field) => @state.errors[field]?
            return if errors then ' has-error' else ''

        getError = (field) =>
            if @state.errors[field]?
                div
                    className: 'col-sm-5 col-sm-offset-2 control-label',
                    @state.errors[field]

        name = @props.name
        type = @props.type or 'text'
        errorField = @props.errorField or name

        div
            key: "account-input-#{name}",
            className: "form-group account-item-#{name} " + hasError(errorField),
                label
                    htmlFor: "mailbox-#{name}",
                    className: "col-sm-2 col-sm-offset-2 control-label",
                    t "account #{name}"
                div className: 'col-sm-3',
                    if type isnt 'checkbox'
                        input
                            id: "mailbox-#{name}",
                            name: "mailbox-#{name}",
                            valueLink: @linkState('value').value,
                            type: type,
                            className: 'form-control',
                            placeholder: if (type is 'text' or type is 'email') then t("account #{name} short") else null
                            onBlur: @props.onBlur or null#@props.validateForm
                            onInput: @props.onInput or null
                    else
                        input
                            id: "mailbox-#{name}",
                            name: "mailbox-#{name}",
                            checkedLink: @linkState('value').value,
                            type: type,
                            onClick: @props.onClick
                getError name
