React      = require 'react'
Immutable = require 'immutable'

{div, ul, span, a, i} = React.DOM

MenuMailboxItem = React.createFactory require './menu_mailbox_item'

classNames = require 'classnames'

{Icons, MessageActions, MessageFilter} = require '../../constants/app_constants'

colorhash = require '../../libs/colorhash'

Routes = require '../../routes'

module.exports = MenuAccountItem = React.createClass
    displayName: 'MenuAccountItem'

    propTypes:
        mailboxID : React.PropTypes.string
        flags : React.PropTypes.string
        account : React.PropTypes.instanceOf(Immutable.Map)
        accountID : React.PropTypes.string # current
        nbUnread : React.PropTypes.number
        nbFlagged : React.PropTypes.number
        displayModal : React.PropTypes.func.isRequired
        isSelected:         React.PropTypes.bool.isRequired
        isMailboxLoading:   React.PropTypes.bool.isRequired
        isRefreshError:     React.PropTypes.bool.isRequired


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
        @props.displayModal modal

    isActive: (mailboxID, flags)->
        @props.mailboxID is mailboxID and
        @props.flags is flags

    getMailboxIcon: (params ) ->
        {account, mailboxID, type} = params
        mailboxID ?= @props.mailboxID

        if type? and (value = Icons[type])
            return {type, value}

        account ?= @props.account
        for type, value of Icons
            if mailboxID is account?.get type
                return {type, value}

    renderMailboxesFlags: (params={}) ->
        {flags, type, slug, mailboxID} = params
        {isMailboxLoading, isRefreshError} = params
        {total, unread} = params

        mailboxURL = Routes.makeURL MessageActions.SHOW_ALL,
            mailboxID: mailboxID
            accountID: @props.account.get('id')
            filter: {flags}

        MenuMailboxItem
            accountID:          @props.account.get('id')
            mailboxID:          mailboxID
            label:              t "mailbox title #{slug}"
            key:                "mailbox-item-#{slug}"
            depth:              0
            url:                mailboxURL
            isActive:           @isActive mailboxID, flags
            displayErrors:      @displayErrors
            isMailboxLoading:   isMailboxLoading
            isRefreshError:     isRefreshError
            total:              total
            unread:             unread
            icon:               @getMailboxIcon {type}

    # renders a single account and its submenu
    # TODO : make a component for this
    render: ->
        # Goto the default mailbox of the account
        accountID = @props.account.get 'id'
        color = colorhash @props.account.get 'label'
        className = classNames active: @props.isSelected
        inboxMailboxes = @props.account.getInboxMailboxes()
        otherMailboxes = @props.account.getOtherMailboxes()


        accountURL = Routes.makeURL MessageActions.SHOW_ALL,
                accountID: @props.account.get('id')
                mailboxID: @props.account.get('inboxMailbox')
                resetFilter: true
            , false

        # configURL = Routes.makeURL AccountActions.EDIT,
        #         accountID: @props.account.get('id')
        #         tab: 'account'
        #     , false

        div
            className: className
            ref: "menuLink-account"
            key: "menuLink-account-#{accountID}",
            div className: 'account-title',
                a
                    href: accountURL
                    role: 'menuitem'
                    className: 'account ' + className,
                    'data-toggle': 'tooltip'
                    'data-delay': '10000'
                    'data-placement' : 'right',
                        i
                            className: 'avatar'
                            style: backgroundColor: color
                            @props.account.get('label')[0]
                        div
                            className: 'account-details',
                                span
                                    'data-account-id': @props.key,
                                    className: 'item-label display-login'
                                    @props.account.get 'login'


            if @props.isSelected
                ul
                    role: 'group'
                    className: 'list-unstyled mailbox-list',

                    # Default Inbox Mailboxes
                    inboxMailboxes?.map (mailbox, key) =>
                        mailboxURL = Routes.makeURL MessageActions.SHOW_ALL,
                            accountID: @props.account.get('id')
                            mailboxID: (mailboxID = mailbox.get 'id')

                        active = @isActive mailboxID
                        account = @props.account
                        icon = @getMailboxIcon {account, mailboxID}

                        MenuMailboxItem
                            key:                'mailbox-item-' + key
                            accountID:          @props.account.get 'id'
                            mailboxID:          mailboxID
                            label:              mailbox.get 'label'
                            depth:              mailbox.get('tree').length - 1
                            isActive:           active
                            displayErrors:      @displayErrors
                            isMailboxLoading:   @props.isMailboxLoading
                            isRefreshError:     @props.isRefreshError
                            url:                mailboxURL
                            total:              mailbox.get 'nbTotal'
                            unread:             mailbox.get 'nbUnread'
                            recent:             mailbox.get 'nbRecent'
                            icon:               icon
                    .toArray()

                    # Unread Mailbox
                    @renderMailboxesFlags
                        type:               'unreadMailbox'
                        flags:              MessageFilter.UNSEEN
                        isMailboxLoading:   @props.isMailboxLoading
                        isRefreshError:     @props.isRefreshError
                        total:              @props.nbUnread
                        unread:             @props.nbUnread
                        slug:               'unread'
                        mailboxID:          @props.account.get 'inboxMailbox'

                    # Flagged Mailbox
                    @renderMailboxesFlags
                        type:               'flaggedMailbox'
                        flags:              MessageFilter.FLAGGED
                        isMailboxLoading:   @props.isMailboxLoading
                        isRefreshError:     @props.isRefreshError
                        total:              @props.nbFlagged
                        unread:             @props.nbFlagged
                        slug:               'flagged'
                        mailboxID:          @props.account.get 'inboxMailbox'

                    # Other mailboxes
                    otherMailboxes?.map (mailbox, key) =>
                        mailboxURL = Routes.makeURL MessageActions.SHOW_ALL,
                            accountID: mailbox.get('accountID')
                            mailboxID: (mailboxID = mailbox.get 'id')

                        active = @isActive mailboxID
                        account = @props.account
                        icon = @getMailboxIcon {account, mailboxID}

                        MenuMailboxItem
                            key:                'mailbox-item-' + key
                            accountID:          @props.account.get 'id'
                            mailboxID:          mailboxID
                            label:              mailbox.get 'label'
                            depth:              mailbox.get('tree').length - 1
                            isActive:           active
                            displayErrors:      @displayErrors
                            isMailboxLoading:   @props.isMailboxLoading
                            isRefreshError:     @props.isRefreshError
                            url:                mailboxURL
                            total:              mailbox.get 'nbTotal'
                            unread:             mailbox.get 'nbUnread'
                            recent:             mailbox.get 'nbRecent'
                            icon:               icon
                    .toArray()
