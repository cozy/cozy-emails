{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM
{MessageFlags, MailboxFlags} = require '../constants/app_constants'
{Icon} = require './basic_components'
RouterMixin           = require '../mixins/router_mixin'
classer      = React.addons.classSet
MessageUtils = require '../utils/message_utils'
colorhash    = require '../utils/colorhash'
Participants        = require './participant'
MessageActionCreator = require '../actions/message_action_creator'


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

        classes = classer
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
                        className: 'select'
                        onClick:   @onSelect
                        type: (if @props.selected then 'check-square-o'
                        else 'square-o')

                    if MessageFlags.SEEN in flags
                        Icon type: 'circle'

                    if MessageFlags.FLAGGED in flags
                        Icon type: 'star'

                div className: 'avatar-wrapper select-target',
                    if avatar?
                        img className: 'avatar', src: avatar
                    else
                        from  = message.get('from')[0]
                        cHash = "#{from?.name} <#{from?.address}>"
                        i
                            className: 'avatar placeholder'
                            style:
                                'background-color': colorhash(cHash)
                            if from?.name then from?.name[0] else from?.address[0]

                div className: 'metas-wrapper',
                    div className: 'participants ellipsable',
                        @getParticipants message
                    div className: 'subject ellipsable',
                        p null,
                            message.get 'subject'
                    div className: 'mailboxes',
                        @getMailboxTags(message)...
                    div className: 'date',
                        # TODO: use time-elements component here for the date
                        date
                    div className: 'extras',
                        if message.get 'hasAttachments'
                            i className: 'attachments fa fa-paperclip'
                        if @props.displayConversations and
                           @props.conversationLengths > 1
                            span className: 'conversation-length',
                                "#{@props.conversationLengths}"
                    div className: 'preview',
                        p null, MessageUtils.getPreview(message)

    _doCheck: ->
        # please don't ask me why this **** react needs this
        if @props.selected
            setTimeout =>
                @refs.select?.getDOMNode().checked = true
            , 50
        else
            setTimeout =>
                @refs.select?.getDOMNode().checked = false
            , 50

    getMailboxTags: ->

        accountID = @props.message.get('accountID')
        accountLabel = @props.accounts.get(accountID).get 'label'

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
                label = "#{accountLabel}:#{label}"

            span className: 'mailbox-tag', label

    componentDidMount: ->
        @_doCheck()

    componentDidUpdate: ->
        @_doCheck()

    onSelect: (e) ->
        @props.onSelect(not @props.selected)
        e.preventDefault()
        e.stopPropagation()

    getUrl: ->
        params =
            messageID: @props.message.get 'id'

        if MessageFlags.DRAFT in @props.message.get('flags') and
        not @props.isTrash
            action = 'edit'
        else
            conversationID = @props.message.get 'conversationID'
            if conversationID? and @props.displayConversations
                action = 'conversation'
                params.conversationID = conversationID
            else
                action = 'message'

        return @buildUrl
            direction: 'second'
            action: action
            parameters: params

    onMessageClick: (event) ->
        node = @refs.target.getDOMNode()
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

        if @props.displayConversations
            data.conversationID = event.currentTarget.dataset.conversationId
        else
            data.messageID = event.currentTarget.dataset.messageId

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
