_     = require 'underscore'
React = require 'react'

{div, ul, li, p, span, a, button, input} = React.DOM

RouterMixin = require '../mixins/router_mixin'


module.exports = React.createClass

    displayName: 'AccountPicker'


    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))


    render: ->
        accounts = @props.accounts
        if Object.keys(accounts).length is 1
            @renderNoChoice()
        else
            @renderPicker()


    onChange: ({target: dataset: value: accountID})->
        @props.valueLink.requestChange accountID

    renderLabel: (account) ->
        if typeof account is 'string'
            account
        else
            label = account.get('name') or account.get('label')
            return "#{label} <#{account.get 'login'}>"


    renderNoChoice: ->
        account = @props.accounts.get @props.valueLink.value

        p className: 'form-control-static align-item', @renderLabel(account)


    renderPicker:  ->
        account  = @props.accounts.get @props.valueLink.value

        div className: 'account-picker align-item',
            span
                className: 'compose-from dropdown-toggle',
                'data-toggle': 'dropdown',
                    span
                        ref: 'account',
                        'data-value': @props.valueLink.value,
                        @renderLabel(account)
                    span className: 'caret'
            ul className: 'dropdown-menu', role: 'menu',
                @props.accounts
                    .filter (account, key) => key isnt @props.valueLink.value
                    .map (account, key) => @renderAccount(key, account)
                    .toArray()


    renderAccount: (key, account) ->
        li
            role: 'presentation',
            key: key,
                a
                    role: 'menuitem',
                    onClick: @onChange,
                    'data-value': key,
                    @renderLabel(account)
