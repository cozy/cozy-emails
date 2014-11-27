{div, ul, li, p, span, a, button, input} = React.DOM

RouterMixin = require '../mixins/router_mixin'

module.exports = React.createClass
    displayName: 'AccountPicker'



    render: ->
        if accounts.length is 1
            @renderNoChoice()
        else
            @renderPicker()

    onChange: ({target: dataset: value: accountID})->
        @props.valueLink.requestChange accountID


    renderNoChoice: ->
        account = @props.accounts.get @props.valueLink.value

        p className: 'form-control-static col-sm-3', account.get 'label'


    renderPicker:  ->
        accounts = @props.accounts
        account  = accounts.get @props.valueLink.value
        value    = @props.valueLink.value
        if @props.type is 'address'
            label = "\"#{account.get('name') or account.get('label')}\" <#{account.get 'login'}>"
        else
            label = account.label

        div null,
            span
                className: 'compose-from dropdown-toggle',
                'data-toggle': 'dropdown',
            #button
            #    id: 'compose-from',
            #    className: 'btn btn-default dropdown-toggle',
            #    type: 'button',
            #    'data-toggle': 'dropdown',
                    span ref: 'account', label
                    span className: 'caret'
            ul className: 'dropdown-menu', role: 'menu',
                for key, account of accounts.toJS() when key isnt value
                    @renderAccount(key, account)

    renderAccount: (key, account) ->
        console.log account
        if @props.type is 'address'
            label = "\"#{account.name or account.label}\" <#{account.login}>"
        else
            label = account.label

        li
            role: 'presentation',
            key: key,
                a
                    role: 'menuitem',
                    onClick: @onChange,
                    'data-value': key,
                    label


