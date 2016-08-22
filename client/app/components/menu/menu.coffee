React      = require 'react'
Immutable = require 'immutable'

{ aside, nav, span, a, i} = React.DOM

MenuAccountItem = React.createFactory require './menu_account_item'

module.exports = Menu = React.createClass
    displayName: 'Menu'

    propTypes:
        mailboxID : React.PropTypes.string
        flags : React.PropTypes.string
        accountID : React.PropTypes.string # current Account
        accounts : React.PropTypes.instanceOf(Immutable.Map).isRequired
        newAccountURL : React.PropTypes.string.isRequired
        nbUnread : React.PropTypes.number
        nbFlagged : React.PropTypes.number
        displayModal : React.PropTypes.func.isRequired
        isMailboxLoading: React.PropTypes.bool.isRequired
        isRefreshError: React.PropTypes.bool.isRequired


    render: ->
        aside
            role: 'menubar'
            'aria-expanded': true,

            nav className: 'mainmenu',
                @props.accounts.map (account) ->
                    MenuAccountItem
                        key: "menu-account-item-#{account.get('id')}"
                        account: account
                        mailboxID : @props.mailboxID
                        flags : @props.flags
                        accountID : @props.accountID
                        nbUnread : @props.nbUnread
                        nbFlagged : @props.nbFlagged
                        displayModal : @props.displayModal
                        isSelected: account.get('id') is @props.accountID
                        mailboxURL: account.makeInboxURL()
                        configURL: account.makeConfigURL()
                        isMailboxLoading: @props.isMailboxLoading
                        isRefreshError: @props.isRefreshError
                .toArray()

            nav className: 'submenu',
                a
                    href: @props.newAccountURL
                    role: 'menuitem'
                    className: "btn new-account-action",
                        i className: 'fa fa-plus'

                        span className: 'item-label',
                        t 'menu account new'
