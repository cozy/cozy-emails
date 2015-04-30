{span, button, img} = React.DOM

LayoutActionCreator  = require '../actions/layout_action_creator'

{Spinner} = require './basic_components'

# This component is the refresh button, which is replaced by a progress
# indicator if a refresh is running.
module.exports = React.createClass
    displayName: 'RefreshIndicator'

    protoTypes:
        refreshes: React.PropTypes.object.isRequired
        selectedAccount: React.PropTypes.object.isRequired
        selectedMailboxID: React.PropTypes.string

    # Define a flag to know if the user has clicked in order to show the spinner
    # immediately, otherwise there is a small time before it starts due to some
    # actions being performed on the server before refresh actuall starts.
    # See #332.
    getInitialState: ->
        isRefreshStarted: false


    render: ->
        span className: 'menu-item trigger-refresh-action',

            # Show the button to trigger a refresh if no refresh are occuring
            # and the user has not triggered it.
            if @props.refreshes.length is 0 and not @state.isRefreshStarted
                button
                    className: ''
                    type: 'button'
                    disabled: null
                    title: t("menu last refresh", date: @getFormattedDate())
                    onClick: @refresh,
                        span className: 'fa fa-refresh'
                        span null, t("menu refresh label")


            # Or an indicator of the progress if a refresh is occurring.
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

                        # If refresh has been triggered, but the component is
                        # waiting for data from the server.
                        else if @state.isRefreshStarted
                            span key: 'sync-box', t("menu refresh initializing")

                        # This is a weird state that should not occur, why it
                        # happens has not been figured out yet. A placeholder
                        # string is used in the meantime.
                        else
                            span key: 'waiting', t("menu refresh waiting")

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


    # Format the last refresh date based on selected mailbox. If none is
    # selected, the first one of the account will be used.
    getFormattedDate: ->
        if @props.selectedMailboxID?
            mailbox = @props.mailboxes.get @props.selectedMailboxID
        else
            mailbox = @props.mailboxes.first()

        date = mailbox.get 'lastSync'
        formatter = 'DD/MM/YYYY HH:mm:ss'
        formattedDate = moment(date).format formatter

        return formattedDate


    # Trigger the refresh action.
    refresh: (event) ->
        @setState isRefreshStarted: true
        event.preventDefault()
        LayoutActionCreator.refreshMessages()


    # Set the `isRefreshStarted` flag to false if it has been set to true
    # and the actual refresh info are coming.
    componentWillReceiveProps: (props) ->
        if props.refreshes.length > 0 and @state.isRefreshStarted
            @setState isRefreshStarted: false
