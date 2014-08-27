React = require 'react/addons'
{div, ul, li, span, a, button} = React.DOM

RouterMixin = require '../mixins/RouterMixin'

module.exports = React.createClass
    displayName: 'MailboxList'

    mixins: [RouterMixin]

    render: ->
        if @props.mailboxes.length > 0
            firstItem = @props.selectedMailbox
            div className: 'dropdown pull-left',
                button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown',
                    firstItem.get 'name'
                    span className: 'caret', ''
                ul className: 'dropdown-menu', role: 'menu',
                    @props.mailboxes.map (mailbox, key) =>
                        if mailbox.get('id') isnt @props.selectedMailbox.get('id')
                            @getMailboxRender mailbox, key
                    .toJS()
        else
            div null, t "app loading"


    getMailboxRender: (mailbox, key) ->
        url = @buildUrl
                direction: 'left'
                action: 'account.mailbox.messages'
                parameters: [@props.selectedAccount.get('id'), mailbox.get('id')]

        li role: 'presentation', key: key,
            a href: url, role: 'menuitem', mailbox.get 'name'
