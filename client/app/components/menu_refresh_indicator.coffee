{span, button, img} = React.DOM

LayoutActionCreator  = require '../actions/layout_action_creator'

{Spinner} = require './basic_components'

module.exports = React.createClass
    displayName: 'RefreshIndicator'

    protoTypes:
        refreshes: React.PropTypes.object.isRequired

    render: ->
        span className: 'menu-item trigger-refresh-action',
            # Show the button to trigger a refresh.
            if @props.refreshes.length is 0
                button
                    className: '',
                    type: 'button',
                    disabled: null,
                    onClick: @refresh,
                        span className: 'fa fa-refresh'
                        span null, 'Refresh'

            # Or an indicator of the progress if a refresh is already occurring.
            else
                {account, mailbox} = @getRefreshInfo()
                [
                        Spinner key: 'spinner', white: true
                    ,

                        # At the beginning and the end, there is only the
                        # account.
                        if account and not mailbox
                            if account.get('done') < account.get('total')
                                span key: 'init', t("menu refresh initializing")
                            else
                                span key: 'clean', t("menu refresh cleaning")

                        # Mark the progress for the mailbox being refreshed.
                        else if account and mailbox
                            done = mailbox.get 'done'
                            total = mailbox.get 'total'
                            progress = Math.round done * 100 / total
                            span key: 'progress', t "menu refresh indicator",
                                account: account.get('account')
                                mailbox: mailbox.get('box')
                                progress: progress
                ]


    # Extract account and mailbox info from the refreshes list.
    getRefreshInfo: ->
        accounts = @props.refreshes.filter (refresh) ->
            return refresh.get('code') is 'account-fetch'
        mailboxes = @props.refreshes.filter (refresh) ->
            return refresh.get('code') is 'box-fetch'

        # There is always only one account and only one mailbox.
        account = accounts.first()
        mailbox = mailboxes.first()

        return {account, mailbox}


    refresh: (event) ->
        event.preventDefault()
        LayoutActionCreator.refreshMessages()
