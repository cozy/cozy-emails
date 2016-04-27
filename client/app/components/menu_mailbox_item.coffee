_          = require 'underscore'
React      = require 'react'
classNames = require 'classnames'

{div, aside, nav, ul, li, span, a, i, button} = React.DOM

MessageActionCreator = require '../actions/message_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
AccountActionCreator = require '../actions/account_action_creator'

{Tooltips} = require '../constants/app_constants'


module.exports = React.createClass
    displayName: 'MenuMailboxItem'

    getInitialState: ->
        return target: false

    getDefaultProps: ->
        return {
            icon: {
                type: null
                value: 'fa-folder-o'
            }
        }

    getTitle: ->
        title = t "menu mailbox total", @props.total
        if @props.unread
            title += t "menu mailbox unread", @props.unread
        if @props.recent
            title += t "menu mailbox new", @props.recent
        return title

    render: ->
        classesParent = classNames
            active: @props.isActive
            target: @state.target

        classesChild = classNames
            target:  @state.target
            special: @props.icon.type
            news:    @props.recent > 0

        displayError = @props.displayErrors.bind null, @props.progress

        li className: classesParent,
            a
                href: @props.url
                className: "#{classesChild} lv-#{@props.depth}"
                role: 'menuitem'
                'data-mailbox-id': @props.mailboxID
                onDragEnter: @onDragEnter
                onDragLeave: @onDragLeave
                onDragOver: @onDragOver
                onDrop: (e) =>
                    @onDrop e, @props.mailboxID
                title: @getTitle()
                'data-toggle': 'tooltip'
                'data-placement' : 'right'
                key: @props.key,
                    i className: 'fa ' + @props.icon.value
                    span
                        className: 'item-label',
                        "#{@props.label}"

                if @props.progress?.get('errors').length
                    span className: 'refresh-error', onClick: displayError,
                        i className: 'fa fa-warning', null

            if 'trashMailbox' is @props.icon?.type
                button
                    className:                'menu-subaction'
                    'aria-describedby':       Tooltips.EXPUNGE_MAILBOX
                    'data-tooltip-direction': 'right'
                    onClick: @expungeMailbox

                    span className: 'fa fa-recycle'

            if not @props.progress and @props.unread
                span className: 'badge', @props.unread


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
                    accountID: @props.accountID
                    mailboxID: @props.mailboxID
