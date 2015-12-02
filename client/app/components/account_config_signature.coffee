{div, h4, ul, li, span, form, i, input, label} = React.DOM
classer = React.addons.classSet

AccountActionCreator = require '../actions/account_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
RouterMixin = require '../mixins/router_mixin'
AccountInput = require './account_config_input'
ShouldComponentUpdate = require '../mixins/should_update_mixin'
cachedTransform = require '../libs/cached_transform'
{Form, FieldSet, FormButtons, FormButton} = require './basic_components'


# Component to handle account signature modification.
# It's a form with a single textarea.
module.exports = React.createClass
    displayName: 'AccountConfigSignature'

    mixins: [
        React.addons.LinkedStateMixin # two-way data binding
        ShouldComponentUpdate.UnderscoreEqualitySlow
    ]

    propTypes:
        editedAccount: React.PropTypes.instanceOf(Immutable.Map).isRequired
        requestChange: React.PropTypes.func.isRequired
        errors: React.PropTypes.instanceOf(Immutable.Map).isRequired
        onSubmit: React.PropTypes.func.isRequired
        saving: React.PropTypes.bool.isRequired

    makeLinkState: (field) ->
        currentValue = @props.editedAccount.get(field)
        cachedTransform @, '__cacheLS', currentValue, =>
            value: currentValue
            requestChange: (value) =>
                changes = {}
                changes[field] = value
                @props.requestChange changes

    # Render a form with a single entry for the account signature.
    render: ->
        Form className: 'form-horizontal form-account account-signature-form',
            FieldSet text: t('account signature'),
                AccountInput
                    type: 'textarea'
                    name: 'signature'
                    valueLink: @makeLinkState 'signature'
                    errors: @props.errors

            FieldSet text: t('account actions'),
                FormButtons null,
                    FormButton
                        className: 'signature-save'
                        spinner: @props.saving
                        icon: 'save'
                        onClick: @props.onSubmit
                        text: t 'account signature save'

