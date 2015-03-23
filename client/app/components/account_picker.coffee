{div, ul, li, p, span, a, button, input} = React.DOM

RouterMixin = require '../mixins/router_mixin'

module.exports = React.createClass
    displayName: 'AccountPicker'

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))

    render: ->
        if Object.keys(accounts).length is 1
            @renderNoChoice()
        else
            @renderPicker()

    onChange: ({target: dataset: value: accountID})->
        @props.valueLink.requestChange accountID

    renderNoChoice: ->
        account = @props.accounts[@props.valueLink.value]

        label = "\"#{account.name or account.label}\" <#{account.login}>"
        p className: 'form-control-static col-sm-6', label

    renderPicker:  ->
        accounts = @props.accounts
        account  = accounts[@props.valueLink.value]
        value    = @props.valueLink.value
        label = "\"#{account.name or account.label}\" <#{account.login}>"

        div className: 'account-picker',
            span
                className: 'compose-from dropdown-toggle',
                'data-toggle': 'dropdown',
                    span
                        ref: 'account',
                        'data-value': value,
                        label
                    span className: 'caret'
            ul className: 'dropdown-menu', role: 'menu',
                for key, account of accounts when key isnt value
                    @renderAccount(key, account)

    renderAccount: (key, account) ->
        label = "\"#{account.name or account.label}\" <#{account.login}>"

        li
            role: 'presentation',
            key: key,
                a
                    role: 'menuitem',
                    onClick: @onChange,
                    'data-value': key,
                    label


