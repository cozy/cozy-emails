{div, ul, li, span, a, button} = React.DOM

RouterMixin = require '../mixins/router_mixin'

module.exports = React.createClass
    displayName: 'MailboxList'

    mixins: [RouterMixin]

    onChange: (boxid) ->
        @props.onChange? boxid

    render: ->
        selectedId = @props.selectedMailbox
        if @props.mailboxes? and @props.mailboxes.length > 0
            if selectedId?
                selected = @props.mailboxes.get selectedId
            div className: 'btn-group btn-group-sm dropdown pull-left',
                button
                    className: 'btn btn-default dropdown-toggle',
                    type: 'button',
                    'data-toggle': 'dropdown',
                    selected?.get('label') or t 'mailbox pick one'
                        span className: 'caret', ''
                ul className: 'dropdown-menu', role: 'menu',
                    if @props.allowUndefined and selected
                        li
                            role: 'presentation',
                            key: null,
                            onClick: @onChange.bind(this, null),
                                a role: 'menuitem', t 'mailbox pick null'

                    @props.mailboxes.map (mailbox, key) =>
                        if mailbox.get('id') isnt selectedId
                            @getMailboxRender mailbox, key
                    .toJS()
        else
            # no account selected
            div null, ""


    getMailboxRender: (mailbox, key) ->
        url = @props.getUrl?(mailbox)
        onChange = @onChange.bind(this, key)

        # Mark nested levels with "--" because plain space
        # just doesn't work for some reason
        pusher = ""
        pusher += "--" for i in [1..mailbox.get('depth')] by 1

        li role: 'presentation', key: key, onClick: onChange,
            if url?
                a href: url, role: 'menuitem', "#{pusher}#{mailbox.get 'label'}"
            else
                a role: 'menuitem', "#{pusher}#{mailbox.get 'label'}"

