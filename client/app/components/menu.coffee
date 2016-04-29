_          = require 'underscore'
React      = require 'react'

{div, aside, nav, ul, li, span, a, i, button} = React.DOM

MenuMailboxItem = React.createFactory require './menu_mailbox_item'

classNames = require 'classnames'
colorhash = require '../utils/colorhash'

LayoutActionCreator  = require '../actions/layout_action_creator'
{MessageFilter, Tooltips, AccountActions, MessageActions} = require '../constants/app_constants'

RouterStore = require '../stores/router_store'
StoreWatchMixin = require '../mixins/store_watch_mixin'

RouterGetter = require '../getters/router'
IconGetter = require '../getters/icon'

module.exports = Menu = React.createClass
    displayName: 'Menu'

    mixins: [
        StoreWatchMixin [RouterStore]
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

                        span className: 'item-label',
                        t 'menu account new'

                button
                    role: 'menuitem'
                    className: 'btn fa fa-question-circle help'
                    'aria-describedby': Tooltips.HELP_SHORTCUTS
                    'data-tooltip-direction': 'top'
                    onClick: -> Mousetrap.trigger '?'

    renderMailboxesFlags: (params={}) ->
        {flags, type, progress, slug, total, unread} = params

        mailbox = RouterGetter.getInbox()
        mailboxURL = RouterGetter.getURL
            mailboxID: (mailboxID = mailbox.get 'id')
            filter: {flags}

        MenuMailboxItem
            accountID:      RouterGetter.getAccountID()
            mailboxID:      mailboxID
            label:          t "mailbox title #{slug}"
            key:            "mailbox-item-#{slug}"
            depth:          0
            url:            mailboxURL
            isActive:       RouterGetter.isCurrentURL mailboxURL
            displayErrors:  @displayErrors
            progress:       progress
            total:          total
            unread:         unread
            icon:           IconGetter.getMailboxIcon {type}

    # renders a single account and its submenu
    # TODO : make a component for this
    renderMailBoxes: (account) ->
        # Goto the default mailbox of the account
        action = MessageActions.SHOW_ALL
        accountID = account.get 'id'
        mailbox = RouterGetter.getInbox(accountID)
        mailboxID = mailbox?.get 'id'
        mailboxURL = RouterGetter.getURL {action, mailboxID, resetFilter: true}

        props = {
            key: 'account-' + accountID
            isSelected: accountID is RouterGetter.getAccountID()
            mailboxes: RouterGetter.getMailboxes()
            mailboxURL: mailboxURL
            configURL: RouterGetter.getURL
                action: AccountActions.EDIT
                accountID: accountID
            nbUnread: account.get 'totalUnread'
            color: colorhash account.get 'label'
            progress: RouterGetter.getProgress accountID
        }

        mailboxes = @state.mailboxes.toArray()
        className = classNames active: props.isSelected
        div
            className: className,
            key: props.key,
            div className: 'account-title',
                a
                    href: props.mailboxURL
                    role: 'menuitem'
                    className: 'account ' + className,
                    'data-toggle': 'tooltip'
                    'data-delay': '10000'
                    'data-placement' : 'right',
                        i
                            className: 'avatar'
                            style: backgroundColor: props.color
                            account.get('label')[0]
                        div
                            className: 'account-details',
                                span
                                    'data-account-id': props.key,
                                    className: 'item-label display-login'
                                    account.get 'login'

                a
                    href: props.configURL
                    className: 'mailbox-config menu-subaction',
                    i
                        'className': 'fa fa-cog'
                        'aria-describedby': Tooltips.ACCOUNT_PARAMETERS
                        'data-tooltip-direction': 'right'

            if props.isSelected
                ul
                    role: 'group'
                    className: 'list-unstyled mailbox-list',

                    mailboxes.map (mailbox, key) =>
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

                    @renderMailboxesFlags
                        type: 'unreadMailbox'
                        flags: MessageFilter.UNSEEN
                        progress: props.progress
                        total: (total = RouterStore.getInbox().get 'nbUnread')
                        unread: total
                        slug: 'unread'

                    @renderMailboxesFlags
                        type: 'flaggedMailbox'
                        flags: MessageFilter.FLAGGED
                        progress: props.progress
                        total: (total = RouterStore.getInbox().get 'nbFlagged')
                        unread: total
                        slug: 'flagged'
