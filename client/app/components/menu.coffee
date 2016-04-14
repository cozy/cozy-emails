_          = require 'underscore'
React      = require 'react'

{div, aside, nav, ul, li, span, a, i, button} = React.DOM

MenuMailboxItem = React.createFactory require './menu_mailbox_item'

classNames = require 'classnames'
colorhash = require '../utils/colorhash'

LayoutActionCreator  = require '../actions/layout_action_creator'
{MessageFilter, Tooltips, AccountActions} = require '../constants/app_constants'

RouterStore = require '../stores/router_store'
AccountStore = require '../stores/account_store'
StoreWatchMixin = require '../mixins/store_watch_mixin'

RouterGetter = require '../getters/router'
IconGetter = require '../getters/icon'

module.exports = Menu = React.createClass
    displayName: 'Menu'

    mixins: [
        StoreWatchMixin [AccountStore, RouterStore]
    ]

    getStateFromStores: ->
        # FIXME : mettre ici le nb de messages non lu
        # de la mailbox courante
        return {
            mailboxes: RouterGetter.getMailboxes()
        }

    # FIXME : déplacer ça dans ModalStore
    # et dispatcher un DISPLAY_MODAL
    # via un ModalActionCreator
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

    renderMailboxesFlags: (params={}) ->
        {flags, type, progress, slug} = params

        accountID = RouterGetter.getAccountID()
        mailbox = RouterGetter.getInbox()
        mailboxID = mailbox.get 'id'
        mailboxURL = RouterGetter.getURL
            mailboxID: mailboxID
            filter: {flags}

        MenuMailboxItem
            accountID:      accountID
            mailboxID:      mailboxID
            label:          t "mailbox title #{slug}"
            key:            "mailbox-item-#{slug}"
            depth:          0
            url:            mailboxURL
            isActive:       RouterGetter.isCurrentURL mailboxURL
            displayErrors:  @displayErrors
            progress:       progress
            total:          mailbox.get 'nbTotal'
            unread:         mailbox.get 'nbUnread'
            recent:         mailbox.get 'nbRecent'
            icon:           IconGetter.getMailboxIcon {type}

    # renders a single account and its submenu
    # FIXME : make a component for this
    renderMailBoxes: (account) ->
        accountID = account.get 'id'

        props = {
            key: 'account-' + accountID
            isSelected: accountID is RouterGetter.getAccountID()
            configURL: RouterGetter.getURL
                action: AccountActions.EDIT
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
                    href: props.configURL
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

                    @state.mailboxes?.map (mailbox, key) =>
                            mailboxURL = RouterGetter.getURL
                                mailboxID: (mailboxID = mailbox.get 'id')
                                resetFilter: true

                            MenuMailboxItem
                                key:            'mailbox-item-' + key
                                accountID:      account.get 'id'
                                mailboxID:      mailboxID
                                label:          mailbox.get 'label'
                                depth:          mailbox.get 'depth'
                                isActive:       RouterGetter.isCurrentURL mailboxURL
                                displayErrors:  @displayErrors
                                progress:       props.progress
                                url:            mailboxURL
                                total:          mailbox.get 'nbTotal'
                                unread:         mailbox.get 'nbUnread'
                                recent:         mailbox.get 'nbRecent'
                                icon:           IconGetter.getMailboxIcon {account, mailboxID}
                        .toArray()

                    @renderMailboxesFlags
                        type: 'unreadMailbox'
                        flags: MessageFilter.UNSEEN
                        progress: props.progress
                        slug: 'unread'
