_          = require 'underscore'
React      = require 'react'
classNames = require 'classnames'

{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM

{MessageFlags, MailboxFlags} = require '../constants/app_constants'
colorhash                    = require '../utils/colorhash'
MessageUtils                 = require '../utils/message_utils'

RouterMixin          = require '../mixins/router_mixin'
MessageActionCreator = require '../actions/message_action_creator'

{Icon}       = require('./basic_components').factories
Participants = React.createFactory require './participants'


module.exports = MessageItem = React.createClass
    displayName: 'MessagesItem'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        # we must do the comparison manually because the property "onSelect" is
        # a function (therefore it should not be compared)
        updatedProps = Object.keys(nextProps).filter (prop) =>
            return typeof nextProps[prop] isnt 'function' and
                not (_.isEqual(nextProps[prop], @props[prop]))
        shouldUpdate = not _.isEqual(nextState, @state) or
            updatedProps.length > 0

        return shouldUpdate

    render: ->
        message = @props.message
        flags = message.get('flags')

        classes = classNames
            message: true
            unseen:  MessageFlags.SEEN not in flags
            active:  @props.isActive
            edited:  @props.edited

        compact = @props.settings.get('listStyle') is 'compact'
        date    = MessageUtils.formatDate message.get('createdAt'), compact
        avatar  = MessageUtils.getAvatar message

        # Change tag type if current message is in edited mode
        tagType  = if @props.edited then span else a


        li
            className:              classes
            key:                    @props.key
            'data-message-id':      message.get('id')
            'data-conversation-id': message.get('conversationID')
            draggable:              not @props.edited
            onClick:                @onMessageClick
            onDragStart:            @onDragStart,

            tagType
                href:              @getUrl()
                className:         'wrapper'
                'data-message-id': message.get('id')
                onClick:           @onMessageClick
                onDoubleClick:     @onMessageDblClick
                ref:               'target'

                div className: 'markers-wrapper',
                    Icon
                        type: 'new-icon'
                        className: 'hidden' if MessageFlags.SEEN in flags

                    Icon
                        className: 'select'
                        onClick:   @onSelect
                        type: (if @props.selected then 'check-square-o'
                        else 'square-o')

                    Icon
                        type: 'star'
                        className: 'hidden' if MessageFlags.FLAGGED not in flags


                div className: 'avatar-wrapper select-target',
                    if avatar?
                        img className: 'avatar', src: avatar
                    else
                        from  = message.get('from')[0]
                        cHash = "#{from?.name} <#{from?.address}>"
                        i
                            className: 'avatar placeholder'
                            style:
                                backgroundColor: colorhash(cHash)
                            if from?.name then from?.name[0] else from?.address[0]

                div className: 'metas-wrapper',
                    div className: 'metas',
                        div className: 'participants ellipsable',
                            @getParticipants message
                        div className: 'subject ellipsable',
                            @highlightSearch message.get('subject')
                        div className: 'mailboxes',
                            @getMailboxTags(message)...
                        div className: 'date',
                            # TODO: use time-elements component here for the date
                            date
                        div className: 'extras',
                            if message.get 'hasAttachments'
                                i className: 'attachments fa fa-paperclip'
                            if @props.conversationLengths > 1
                                span className: 'conversation-length',
                                    "#{@props.conversationLengths}"
                        div className: 'preview ellipsable',
                            @highlightSearch MessageUtils.getPreview(message)

    highlightSearch: (text, opts = null) ->
        return p opts, MessageUtils.highlightSearch(text)...

    getMailboxTags: ->

        accountID = @props.message.get('accountID')

        Object.keys @props.message.get('mailboxIDs')
        .filter (boxID) =>
            box = @props.mailboxes.get boxID
            unless box # box was just deleted
                return false

            if @props.mailboxID and MailboxFlags.ALL in box.get 'attribs'
                return false # dont display "all messages" labels

            if @props.mailboxID is boxID
                return false # dont display same box labels

            return true

        .map (boxID) =>
            box = @props.mailboxes.get boxID
            label = box.get 'label'
            unless @props.accountID
                label = "#{@props.accountLabel}:#{label}"

            span className: 'mailbox-tag', label

    onSelect: (e) ->
        @props.onSelect(not @props.selected)
        e.preventDefault()
        e.stopPropagation()

    getUrl: ->
        params =
            messageID: @props.message.get 'id'

        action = 'conversation'
        params.conversationID = @props.message.get 'conversationID'

        return @buildUrl
            direction: 'second'
            action: action
            parameters: params

    onMessageClick: (event) ->
        node = @refs.target
        if @props.edited and event.target.classList.contains 'select-target'
            @props.onSelect(not @props.selected)
            event.preventDefault()
            event.stopPropagation()
        # When hitting `enter` in deletion confirmation dialog, this
        # event is fired on last active link. We must cancel it to prevent
        # navigating to the last message the user clicked
        else if event.target.classList.contains 'wrapper'
            event.preventDefault()
            event.stopPropagation()
        else if not (event.target.getAttribute('type') is 'checkbox')
            event.preventDefault()
            event.stopPropagation()
            MessageActionCreator.setCurrent node.dataset.messageId, true
            if @props.settings.get('displayPreview')
                href = '#' + node.getAttribute('href').split('#')[1]
                @redirect href

    onMessageDblClick: (event) ->
        if not @props.edited
            url = event.currentTarget.href.split('#')[1]
            window.router.navigate url, {trigger: true}

    onDragStart: (event) ->
        event.stopPropagation()
        data = mailboxID: @props.mailboxID
        data.conversationID = event.currentTarget.dataset.conversationId

        event.dataTransfer.setData 'text', JSON.stringify(data)
        event.dataTransfer.effectAllowed = 'move'
        event.dataTransfer.dropEffect = 'move'

    getParticipants: (message) ->
        from = message.get 'from'
        to   = message.get('to').concat(message.get('cc')).filter (address) =>
            return address.address isnt @props.login and
                address.address isnt from[0]?.address
        separator = if to.length > 0 then ', ' else ' '
        p null,
            Participants
                participants: from
                onAdd: @addAddress
                ref: 'from'
                tooltip: false
            span null, separator
            Participants
                participants: to
                onAdd: @addAddress
                ref: 'to'
                tooltip: false

    addAddress: (address) ->
        ContactActionCreator.createContact address
