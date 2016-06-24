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
        {flags, type, slug, mailboxID} = params
        {isMailboxLoading, isRefreshError} = params
        {total, unread} = params

        mailboxURL = RouterGetter.getURL
            mailboxID: mailboxID
            filter: {flags}

        MenuMailboxItem
            accountID:          @props.accountID
            mailboxID:          mailboxID
            label:              t "mailbox title #{slug}"
            key:                "mailbox-item-#{slug}"
            depth:              0
            url:                mailboxURL
            isActive:           RouterGetter.isCurrentURL mailboxURL
            displayErrors:      @displayErrors
            isMailboxLoading:   isMailboxLoading
            isRefreshError:     isRefreshError
            total:              total
            unread:             unread
            icon:               FileGetter.getMailboxIcon {type}

    # renders a single account and its submenu
    # TODO : make a component for this
    renderMailBoxes: (account) ->
        # Goto the default mailbox of the account
        accountID = account.get 'id'
        props = {
            isSelected:         accountID is @props.accountID
            mailboxURL:         RouterGetter.getInboxURL accountID
            configURL:          RouterGetter.getConfigURL accountID
            color:              ContactGetter.getTagColor account.get 'label'
            isMailboxLoading:   RouterGetter.isMailboxLoading()
            isRefreshError:     RouterGetter.isRefreshError()
            inboxMailboxes:     RouterGetter.getInboxMailboxes accountID
            otherMailboxes:     RouterGetter.getOtherMailboxes accountID
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
                    props.inboxMailboxes?.valueSeq().map (mailbox, key) =>
                        mailboxURL = RouterGetter.getURL
                            mailboxID: (mailboxID = mailbox.get 'id')
                            resetFilter: true

                        MenuMailboxItem
                            key:                'mailbox-item-' + key
                            accountID:          account.get 'id'
                            mailboxID:          mailboxID
                            label:              mailbox.get 'label'
                            depth:              mailbox.get('tree').length - 1
                            isActive:           RouterGetter.isCurrentURL mailboxURL
                            displayErrors:      @displayErrors
                            isMailboxLoading:   props.isMailboxLoading
                            isRefreshError:     props.isRefreshError
                            url:                mailboxURL
                            total:              mailbox.get 'nbTotal'
                            unread:             mailbox.get 'nbUnread'
                            recent:             mailbox.get 'nbRecent'
                            icon:               FileGetter.getMailboxIcon {account, mailboxID}

                    # Unread Mailbox
                    @renderMailboxesFlags
                        type:               'unreadMailbox'
                        flags:              MessageFilter.UNSEEN
                        isMailboxLoading:   props.isMailboxLoading
                        isRefreshError:     props.isRefreshError
                        total:              @props.nbUnread
                        unread:             @props.nbUnread
                        slug:               'unread'
                        mailboxID:          account.get 'inboxMailbox'

                    # Flagged Mailbox
                    @renderMailboxesFlags
                        type:               'flaggedMailbox'
                        flags:              MessageFilter.FLAGGED
                        isMailboxLoading:   props.isMailboxLoading
                        isRefreshError:     props.isRefreshError
                        total:              @props.nbFlagged
                        unread:             @props.nbFlagged
                        slug:               'flagged'
                        mailboxID:          account.get 'inboxMailbox'

                    # Other mailboxes
                    props.otherMailboxes?.valueSeq().map (mailbox, key) =>
                        mailboxURL = RouterGetter.getURL
                            mailboxID: (mailboxID = mailbox.get 'id')
                            resetFilter: true

                        MenuMailboxItem
                            key:                'mailbox-item-' + key
                            accountID:          account.get 'id'
                            mailboxID:          mailboxID
                            label:              mailbox.get 'label'
                            depth:              mailbox.get('tree').length - 1
                            isActive:           RouterGetter.isCurrentURL mailboxURL
                            displayErrors:      @displayErrors
                            isMailboxLoading:   props.isMailboxLoading
                            isRefreshError:     props.isRefreshError
                            url:                mailboxURL
                            total:              mailbox.get 'nbTotal'
                            unread:             mailbox.get 'nbUnread'
                            recent:             mailbox.get 'nbRecent'
                            icon:               FileGetter.getMailboxIcon {account, mailboxID}
