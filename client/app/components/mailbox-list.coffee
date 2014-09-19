{div, ul, li, span, a, button} = React.DOM

RouterMixin = require '../mixins/router_mixin'

module.exports = React.createClass
    displayName: 'MailboxList'

    mixins: [RouterMixin]

    render: ->
        if @props.mailboxes.length > 0 and @props.selectedMailbox?
            firstItem = @props.selectedMailbox
            div className: 'dropdown pull-left',
                button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown',
                    firstItem.get 'label'
                    span className: 'caret', ''
                ul className: 'dropdown-menu', role: 'menu',
                    @props.mailboxes.map (mailbox, key) =>
                        if mailbox.get('id') isnt @props.selectedMailbox.get('id')
                            @getMailboxRender mailbox, key
                    .toJS()
        else
            # no account selected
            div null, ""


    getMailboxRender: (mailbox, key) ->
        url = @buildUrl
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: [@props.selectedAccount.get('id'), mailbox.get('id')]

        # Mark nested levels with "--" because plain space just doesn't work for some reason
        pusher = ""
        pusher += "--" for i in [1..mailbox.get('depth')] by 1

        li role: 'presentation', key: key,
            a href: url, role: 'menuitem', "#{pusher}#{mailbox.get 'label'}"
