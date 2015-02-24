# React components
{body, div, p, form, i, input, span, a, button, strong} = React.DOM
MailboxList   = require './mailbox-list'
SearchForm = require './search-form'

# mixins & action creator
RouterMixin = require '../mixins/router_mixin'
LayoutActionCreator = require '../actions/layout_action_creator'

# React addons
ReactCSSTransitionGroup = React.addons.CSSTransitionGroup

module.exports = Topbar = React.createClass
    displayName: 'Topbar'

    mixins: [RouterMixin]

    refresh: (event) ->
        event.preventDefault()
        LayoutActionCreator.refreshMessages()

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->

        {layout, selectedAccount, selectedMailboxID, mailboxes, searchQuery} = @props

        responsiveBackUrl = @buildUrl
            firstPanel: layout.firstPanel
            fullWidth: true

        getUrl = (mailbox) =>
            @buildUrl
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: [selectedAccount?.get('id'), mailbox.id]

        if selectedAccount and layout.firstPanel.action isnt 'account.new'
            # the button toggles the mailbox config
            if layout.firstPanel.action is 'account.config'
                configMailboxUrl = @buildUrl
                    direction: 'first'
                    action: 'account.mailbox.messages'
                    parameters: selectedAccount.get 'id'
                    fullWidth: true
            else
                configMailboxUrl = @buildUrl
                    direction: 'first'
                    action: 'account.config'
                    parameters: [
                        selectedAccount.get 'id'
                        'account'
                    ]
                    fullWidth: true


        div id: 'quick-actions', className: 'row',
            # responsive menu icon
            if layout.secondPanel
                a href: responsiveBackUrl, className: 'responsive-handler hidden-md hidden-lg',
                    i className: 'fa fa-chevron-left hidden-md hidden-lg pull-left'
                    t "app back"

            if layout.firstPanel.action is 'account.mailbox.messages' or
               layout.firstPanel.action is 'account.mailbox.messages'
                div className: 'col-md-6 hidden-xs hidden-sm pull-left',
                    form className: 'form-inline col-md-12',
                        MailboxList
                            getUrl: getUrl
                            mailboxes: mailboxes
                            selectedMailboxID: selectedMailboxID
                        SearchForm query: searchQuery

            if layout.firstPanel.action is 'account.mailbox.messages' or
               layout.firstPanel.action is 'account.mailbox.messages'
                div id: 'contextual-actions', className: 'col-md-6 hidden-xs hidden-sm pull-left text-right',
                    a onClick: @refresh, className: 'btn btn-cozy-contrast',
                        i className: 'fa fa-refresh'
                    ReactCSSTransitionGroup transitionName: 'fade',
                        if configMailboxUrl
                            a href: configMailboxUrl, className: 'btn btn-cozy mailbox-config',
                                i className: 'fa fa-cog'
