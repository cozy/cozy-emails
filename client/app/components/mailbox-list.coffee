{div, ul, li, span, a, button} = React.DOM

RouterMixin = require '../mixins/router_mixin'

module.exports = React.createClass
    displayName: 'MailboxList'

    mixins: [RouterMixin]

    render: ->
        selected = @props.selectedMailbox
        if typeof selected is "string"
            selected = @props.mailboxes.get selected
        if @props.mailboxes.length > 0 and selected?
            div className: 'dropdown pull-left',
                button className: 'btn btn-default dropdown-toggle', type: 'button', 'data-toggle': 'dropdown',
                    selected.get 'label'
                    span className: 'caret', ''
                ul className: 'dropdown-menu', role: 'menu',
                    @props.mailboxes.map (mailbox, key) =>
                        if mailbox.get('id') isnt selected.get('id')
                            @getMailboxRender mailbox, key
                    .toJS()
        else
            # no account selected
            div null, ""


    getMailboxRender: (mailbox, key) ->
        if @props.getUrl?
            url = @props.getUrl(mailbox)

        if @props.onChange
            onChange = =>
                @props.onChange(mailbox)
        else
            onChange = ->

        # Mark nested levels with "--" because plain space just doesn't work for some reason
        pusher = ""
        pusher += "--" for i in [1..mailbox.get('depth')] by 1

        li role: 'presentation', key: key, onClick: onChange,
            if url?
                a href: url, role: 'menuitem', "#{pusher}#{mailbox.get 'label'}"
            else
                a role: 'menuitem', "#{pusher}#{mailbox.get 'label'}"

