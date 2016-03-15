Immutable = require 'immutable'
React = require 'react'

{   Form
    FieldSet
    FormButtons
    FormButton} = require('./basic_components').factories
AccountInput = React.createFactory require './account_config_input'

ShouldComponentUpdate = require '../mixins/should_update_mixin'
LinkedStateMixin      = require 'react-addons-linked-state-mixin'

cachedTransform = require '../libs/cached_transform'


# Component to handle account signature modification.
# It's a form with a single textarea.
module.exports = React.createClass
    displayName: 'AccountConfigSignature'

    mixins: [
        LinkedStateMixin
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
