{ div } = React.DOM

AccountActionCreator = require '../actions/account_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'

{FieldSet, FormButtons} = require './basic_components'

module.exports = AccountConfigDelete = React.createClass
    displayName: 'AccountConfigDelete'


    getInitialState: ->
        state = {}
        state.deleting     = false
        return state

    render: ->
        div null,
            FieldSet text: t 'account danger zone'

            FormButtons
                buttons: [
                    class: 'btn-remove'
                    contrast: false
                    default: true
                    danger: true
                    onClick: @onRemove
                    spinner: @state.deleting
                    icon: 'trash'
                    text: t "account remove"
                ]

    # Ask for confirmation before running remove operation.
    onRemove: (event) ->
        event?.preventDefault()

        label = @props.selectedAccount.get 'label'
        modal =
            title       : t 'app confirm delete'
            subtitle    : t 'account remove confirm', {label: label}
            closeModal  : ->
                LayoutActionCreator.hideModal()
            closeLabel  : t 'app cancel'
            actionLabel : t 'app confirm'
            action      : =>
                LayoutActionCreator.hideModal()
                @setState deleting: true
                AccountActionCreator.remove @props.selectedAccount.get('id')

        LayoutActionCreator.displayModal modal
