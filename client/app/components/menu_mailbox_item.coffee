_          = require 'underscore'
React      = require 'react'
classNames = require 'classnames'

{div, aside, nav, ul, li, span, a, i, button} = React.DOM

RouterGetter = require '../getters/router'

MessageActionCreator = require '../actions/message_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
AccountActionCreator = require '../actions/account_action_creator'

{SpecialBoxIcons, Tooltips} = require '../constants/app_constants'


module.exports = MenuMailboxItem = React.createClass
    displayName: 'MenuMailboxItem'

    getInitialState: ->
        return target: false

    render: ->
        mailboxID = @props.mailbox.get 'id'

        mailboxUrl = RouterGetter.getURL
            mailboxID: mailboxID

        nbTotal  = @props.mailbox.get('nbTotal') or 0
        nbUnread = @props.mailbox.get('nbUnread') or 0
        nbRecent = @props.mailbox.get('nbRecent') or 0
        title    = t "menu mailbox total", nbTotal
        if nbUnread > 0
            title += " #{t "menu mailbox unread", nbUnread}"
        if nbRecent > 0
            title += " #{t "menu mailbox new", nbRecent}"

        mailboxIcon = 'fa-folder-o'
        specialMailbox = false
        for attrib, icon of SpecialBoxIcons
            if @props.account.get(attrib) is mailboxID
                mailboxIcon = icon
                specialMailbox = attrib

        classesParent = classNames
            active: @props.isActive
            target: @state.target

        classesChild = classNames
            target:  @state.target
            special: specialMailbox
            news:    nbRecent > 0
        classesChild += " #{specialMailbox}" if specialMailbox


        progress = @props.refreshes.get mailboxID
        displayError = @props.displayErrors.bind null, progress

        li className: classesParent,
            a
                href: mailboxUrl
                className: "#{classesChild} lv-#{@props.mailbox.get('depth')}"
                role: 'menuitem'
                'data-mailbox-id': mailboxID
                onDragEnter: @onDragEnter
                onDragLeave: @onDragLeave
                onDragOver: @onDragOver
                onDrop: (e) =>
                    @onDrop e, mailboxID
                title: title
                'data-toggle': 'tooltip'
                'data-placement' : 'right'
                key: @props.key,
                    # Something must be rethought about the icon
                    i className: 'fa ' + mailboxIcon
                    span
                        className: 'item-label',
                        "#{@props.mailbox.get 'label'}"

                if progress?.get('errors').length
                    span className: 'refresh-error', onClick: displayError,
                        i className: 'fa fa-warning', null

            if @props.account.get('trashMailbox') is mailboxID
                button
                    className:                'menu-subaction'
                    'aria-describedby':       Tooltips.EXPUNGE_MAILBOX
                    'data-tooltip-direction': 'right'
                    onClick: @expungeMailbox

                    span className: 'fa fa-recycle'

            if not progress and nbUnread and nbUnread > 0
                span className: 'badge', nbUnread


    onDragEnter: (e) ->
        if not @state.target
            @setState target: true

    onDragLeave: (e) ->
        if @state.target
            @setState target: false

    onDragOver: (e) ->
        e.preventDefault()

    onDrop: (event, to) ->
        data = event.dataTransfer.getData('text')
        {messageID, mailboxID, conversationID} = JSON.parse data
        @setState target: false
        MessageActionCreator.move {messageID, conversationID}, mailboxID, to

    expungeMailbox: (event) ->
        event.preventDefault()
        LayoutActionCreator.displayModal
            title       : t 'app confirm delete'
            subtitle    : t 'account confirm delbox'
            closeLabel  : t 'app cancel'
            actionLabel : t 'app confirm'
            action      : =>
                LayoutActionCreator.hideModal()
                AccountActionCreator.mailboxExpunge
                    accountID: @props.account.get 'id'
                    mailboxID: @props.mailbox.get 'id'
