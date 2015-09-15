{div, h4, ul, li, span, form, i, input, label} = React.DOM
classer = React.addons.classSet

AccountActionCreator = require '../actions/account_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
RouterMixin = require '../mixins/router_mixin'
AccountInput = require './account_config_input'
{Form, FieldSet, FormButtons} = require './basic_components'


# Component to handle account signature modification.
# It's a form with a single textarea.
module.exports = React.createClass
    displayName: 'AccountConfigSignature'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
    ]


    # Do not update component if nothing has changed.
    shouldComponentUpdate: (nextProps, nextState) ->
        isNextState = _.isEqual nextState, @state
        isNextProps = _.isEqual nextProps, @props
        return not (isNextState and isNextProps)


    getInitialState: ->
        account: @props.account
        saving: false
        errors: {}
        signature: @props.account.get 'signature'


    # Render a form with a single entry for the account signature.
    render: ->
        console.log @state.account.get 'signature'
        formClass = classer
            'form-horizontal': true
            'form-account': true
            'account-signature-form': true

        Form className: formClass,

            FieldSet
                text: t 'account signature'

            AccountInput
                type: 'textarea'
                name: 'signature'
                value: @linkState 'signature'
                errors: @state.errors
                onBlur: @props.onBlur

            FieldSet
                text: t 'account actions'

            FormButtons
                buttons: [
                    class: 'signature-save'
                    contrast: false
                    default: false
                    danger: false
                    spinner: @state.saving
                    icon: 'save'
                    onClick: @onSubmit
                    text: t 'account signature save'
                ]


    # When data are submitted, it asks to the API to persist the current
    # signature.
    onSubmit: (event) ->
        event.preventDefault() if event?

        @setState saving: true
        @props.editAccount signature: @state.signature, =>
            @setState saving: false

