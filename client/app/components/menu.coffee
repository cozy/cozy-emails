_          = require 'underscore'
React      = require 'react'

{div, aside, nav, ul, li, span, a, i, button} = React.DOM

MenuMailboxItem = React.createFactory require './menu_mailbox_item'

classNames = require 'classnames'
colorhash = require '../utils/colorhash'

LayoutActionCreator  = require '../actions/layout_action_creator'
{Tooltips} = require '../constants/app_constants'

RouterGetter = require '../getters/router'

module.exports = Menu = React.createClass
    displayName: 'Menu'

    displayErrors: (refreshee) ->
        errors = refreshee.get 'errors'
        modal =
            title       : t 'modal please contribute'
            subtitle    : t 'modal please report'
            allowCopy   : true
            closeLabel  : t 'app alert close'
            content     : React.DOM.pre
                style: "max-height": "300px",
                "word-wrap": "normal",
                    errors.join "\n\n"
        LayoutActionCreator.displayModal modal

    render: ->
        aside
            role: 'menubar'
            'aria-expanded': true,

            if @props.accounts.length
                a
                    href: @props.composeURL
                    className: 'compose-action btn btn-cozy',
                        i className: 'fa fa-pencil'
                        span className: 'item-label', " #{t 'menu compose'}"

            nav className: 'mainmenu',
                if @props?.search and not @props.accountID
                    div className: 'active',
                        div className: 'account-title',
                            a
                                role: 'menuitem'
                                className: 'account active',

                                i className: 'fa fa-search'

                                div
                                    className: 'account-details',
                                        span {}, @props?.search

                @props.accounts.map @renderMailBoxes

            nav className: 'submenu',
                a
                    href: @props.newAccountURL
                    role: 'menuitem'
                    className: "btn new-account-action",
                        i className: 'fa fa-plus'
                        span className: 'item-label', t 'menu account new'

                button
                    role: 'menuitem'
                    className: 'btn fa fa-question-circle help'
                    'aria-describedby': Tooltips.HELP_SHORTCUTS
                    'data-tooltip-direction': 'top'
                    onClick: -> Mousetrap.trigger '?'

    # renders a single account and its submenu
    # FIXME : make a component for this
    renderMailBoxes: (account) ->
        accountID = account.get 'id'
        props = {
            key: 'account-' + accountID
            isSelected: accountID is RouterGetter.getAccountID()
            mailboxes: RouterGetter.getMailboxes()
            newAccountURL: RouterGetter.getURL
                action: 'account.new'
                accountID: accountID
            configURL: RouterGetter.getURL
                action: 'account.edit'
                accountID: accountID
            nbUnread: account.get 'totalUnread'
            color: colorhash account.get 'label'
            progress: RouterGetter.getProgress accountID
        }

        div
            className: (className = classNames active: props.isSelected),
            key: props.key,
            div className: 'account-title',
                a
                    href: props.newAccountURL
                    role: 'menuitem'
                    className: 'account ' + className,
                    'data-toggle': 'tooltip'
                    'data-delay': '10000'
                    'data-placement' : 'right',
                        i
                            className: 'avatar'
                            style:
                                backgroundColor: props.color
                            account.get('label')[0]
                        div
                            className: 'account-details',
                                span
                                    'data-account-id': props.key,
                                    className: 'item-label display-label'
                                    account.get 'label'
                                span
                                    'data-account-id': props.key,
                                    className: 'item-label display-login'
                                    account.get 'login'

                    if props.progress?.get('errors')?.size
                        span className: 'refresh-error',
                            i
                                className: 'fa warning',
                                onClick: @displayErrors,
                                props.progress

                if props.isSelected
                    a
                        href: props.configURL
                        className: 'mailbox-config menu-subaction',
                        i
                            'className': 'fa fa-cog'
                            'aria-describedby': Tooltips.ACCOUNT_PARAMETERS
                            'data-tooltip-direction': 'right'

                if props.nbUnread > 0 and not props.progress
                    span className: 'badge', props.nbUnread

            if props.isSelected
                ul
                    role: 'group'
                    className: 'list-unstyled mailbox-list',

                    props.mailboxes?.map (mailbox, key) =>
                            MenuMailboxItem
                                account:           account
                                mailbox:           mailbox
                                key:               'mailbox-item-' + key
                                isActive:          @props.mailboxID is mailbox.get 'id'
                                refreshes:         @state.refreshes
                                displayErrors:     @displayErrors
                                progress:          @props.progress
                        .toArray()
