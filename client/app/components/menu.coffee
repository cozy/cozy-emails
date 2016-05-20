_          = require 'underscore'
React      = require 'react'

{div, aside, nav, ul, li, span, a, i, button} = React.DOM

MenuMailboxItem = React.createFactory require './menu_mailbox_item'

classNames = require 'classnames'

LayoutActionCreator  = require '../actions/layout_action_creator'
{MessageFilter, Tooltips, AccountActions, MessageActions} = require '../constants/app_constants'

RouterGetter = require '../getters/router'
ContactGetter = require '../getters/contact'
FileGetter = require '../getters/file'

module.exports = Menu = React.createClass
    displayName: 'Menu'


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


    renderMailboxesFlags: (params={}) ->
        {flags, type, progress, slug, total, unread, mailboxID} = params

        mailboxURL = RouterGetter.getURL
            mailboxID: mailboxID
            filter: {flags}

        MenuMailboxItem
            accountID:      @props.accountID
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
            icon:           FileGetter.getMailboxIcon {type}

    # renders a single account and its submenu
    # TODO : make a component for this
    renderMailBoxes: (account) ->
        inboxMailboxes = @props.mailboxes.filter (mailbox) ->
            'inbox' is mailbox.get('tree')[0].toLowerCase()
        otherMailboxes = @props.mailboxes.filter (mailbox) ->
            'inbox' isnt mailbox.get('tree')[0].toLowerCase()

        # Goto the default mailbox of the account
        action = MessageActions.SHOW_ALL
        accountID = account.get 'id'
        mailboxID = account.get 'inboxMailbox'
        mailboxURL = RouterGetter.getURL {action, mailboxID, resetFilter: true}

        props = {
            isSelected: accountID is @props.accountID
            mailboxURL: mailboxURL
            configURL: RouterGetter.getURL
                action: AccountActions.EDIT
                accountID: accountID
            nbUnread: account.get 'totalUnread'
            color: ContactGetter.getTagColor account.get 'label'
            progress: RouterGetter.getProgress accountID
        }

        className = classNames active: props.isSelected
        div
            className: className
            ref: "menuLink-account-#{accountID}"
            key: "menuLink-account-#{accountID}",
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


            if props.isSelected
                ul
                    role: 'group'
                    className: 'list-unstyled mailbox-list',

                    # Default Inbox Mailboxes
                    inboxMailboxes?.map (mailbox, key) =>
                        mailboxURL = RouterGetter.getURL
                            mailboxID: (mailboxID = mailbox.get 'id')
                            resetFilter: true

                        MenuMailboxItem
                            key:            'mailbox-item-' + key
                            accountID:      account.get 'id'
                            mailboxID:      mailboxID
                            label:          mailbox.get 'label'
                            depth:          mailbox.get('tree').length - 1
                            isActive:       RouterGetter.isCurrentURL mailboxURL
                            displayErrors:  @displayErrors
                            progress:       props.progress
                            url:            mailboxURL
                            total:          mailbox.get 'nbTotal'
                            unread:         mailbox.get 'nbUnread'
                            recent:         mailbox.get 'nbRecent'
                            icon:           FileGetter.getMailboxIcon {account, mailboxID}

                    # Unread Mailbox
                    @renderMailboxesFlags
                        type: 'unreadMailbox'
                        flags: MessageFilter.UNSEEN
                        progress: props.progress
                        total: @props.nbUnread
                        unread: @props.nbUnread
                        slug: 'unread'
                        mailboxID: account.get 'inboxMailbox'

                    # Flagged Mailbox
                    @renderMailboxesFlags
                        type: 'flaggedMailbox'
                        flags: MessageFilter.FLAGGED
                        progress: props.progress
                        total: @props.nbFlagged
                        unread: @props.nbFlagged
                        slug: 'flagged'
                        mailboxID: account.get 'inboxMailbox'

                    # Other mailboxes
                    otherMailboxes?.map (mailbox, key) =>
                        mailboxURL = RouterGetter.getURL
                            mailboxID: (mailboxID = mailbox.get 'id')
                            resetFilter: true

                        MenuMailboxItem
                            key:            'mailbox-item-' + key
                            accountID:      account.get 'id'
                            mailboxID:      mailboxID
                            label:          mailbox.get 'label'
                            depth:          mailbox.get('tree').length - 1
                            isActive:       RouterGetter.isCurrentURL mailboxURL
                            displayErrors:  @displayErrors
                            progress:       props.progress
                            url:            mailboxURL
                            total:          mailbox.get 'nbTotal'
                            unread:         mailbox.get 'nbUnread'
                            recent:         mailbox.get 'nbRecent'
                            icon:           FileGetter.getMailboxIcon {account, mailboxID}
