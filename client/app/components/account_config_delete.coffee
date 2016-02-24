React = require 'react'

{ div } = React.DOM

AccountActionCreator = require '../actions/account_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'

{FieldSet, FormButtons, FormButton} = require('./basic_components').factories

module.exports = AccountConfigDelete = React.createClass
    displayName: 'AccountConfigDelete'


    getInitialState: ->
        state = {}
        state.deleting     = false
        return state

    render: ->
        FieldSet text: t('account danger zone'),
            FormButtons null,
                FormButton
                    className: 'btn-remove'
                    default: true
                    danger: true
                    onClick: @onRemove
                    spinner: @state.deleting
                    icon: 'trash'
                    text: t "account remove"

    # Ask for confirmation before running remove operation.
    onRemove: (event) ->
        event?.preventDefault()

        label = @props.editedAccount.get 'label'
        LayoutActionCreator.displayModal
            title       : t 'app confirm delete'
            subtitle    : t 'account remove confirm', {label: label}
            closeLabel  : t 'app cancel'
            actionLabel : t 'app confirm'
            action      : =>
                LayoutActionCreator.hideModal()
                @setState deleting: true
                AccountActionCreator.remove @props.editedAccount.get('id')
