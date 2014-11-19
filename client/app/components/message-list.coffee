{div, ul, li, a, span, i, p, button, input, img} = React.DOM
classer = React.addons.classSet

RouterMixin    = require '../mixins/router_mixin'
MessageUtils   = require '../utils/message_utils'
{MessageFlags, MessageFilter} = require '../constants/app_constants'
LayoutActionCreator  = require '../actions/layout_action_creator'
ContactActionCreator = require '../actions/contact_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
MessageStore   = require '../stores/message_store'
Participants   = require './participant'

MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    render: ->
        messages = @props.messages.map (message, key) =>
            isActive = @props.messageID is message.get('id')
            @getMessageRender message, key, isActive
        .toJS()
        nbMessages = parseInt @props.counterMessage, 10
        filterParams =
            accountID: @props.accountID
            mailboxID: @props.mailboxID
            query:     @props.query
        nextPage = =>
            LayoutActionCreator.showMessageList parameters: @props.query
        div className: 'message-list', ref: 'list',
            div className: 'message-list-actions',
                #MessagesQuickFilter {}
                MessagesFilter filterParams
                MessagesSort filterParams
            if @props.messages.count() is 0
                p null, @props.emptyListMessage
            else
                div null,
                    p null, @props.counterMessage
                    ul className: 'list-unstyled',
                        messages
                    if @props.messages.count() < nbMessages
                        p null,
                            a
                                #href: @props.paginationUrl
                                onClick: nextPage,
                                ref: 'nextPage',
                                t 'list next page'
                    else
                        p null, t 'list end'

    getMessageRender: (message, key, isActive) ->
        flags = message.get('flags')
        classes = classer
            message: true
            read: message.get 'isRead'
            active: isActive
            'unseen': flags.indexOf(MessageFlags.SEEN) is -1
            'has-attachments': message.get 'hasAttachments'
            'is-fav': flags.indexOf(MessageFlags.FLAGGED) isnt -1

        isDraft = message.get('flags').indexOf(MessageFlags.DRAFT) isnt -1

        if isDraft
            action = 'edit'
            id     = message.get 'id'
        else
            conversationID = message.get 'conversationID'
            if conversationID and @props.settings.get('displayConversation')
                action = 'conversation'
                id     = message.get 'id'
            else
                action = 'message'
                id     = message.get 'id'
        url = @buildUrl
            direction: 'second'
            action: action
            parameters: id

        date   = MessageUtils.formatDate message.get 'createdAt'
        avatar = MessageUtils.getAvatar message

        li
            className: classes,
            key: key,
            'data-message-id': message.get('id'),
            draggable: true,
            onDragStart: @onDragStart,
                a
                    href: url,
                    'data-message-id': message.get('id'),
                    onClick: @onMessageClick,
                    onDoubleClick: @onMessageDblClick,
                        if avatar?
                            img className: 'avatar', src: avatar
                        else
                            i className: 'fa fa-user'
                        span className: 'participants', @getParticipants message
                        div className: 'preview',
                            span className: 'title', message.get 'subject'
                            p null, message.get('text')?.substr(0, 100) + "…"
                        span className: 'hour', date
                        span className: "flags",
                            i className: 'attach fa fa-paperclip'
                            i className: 'fav fa fa-star'

    onMessageClick: (event) ->
        if not @props.settings.get('displayPreview')
            event.preventDefault()
            MessageActionCreator.setCurrent event.currentTarget.dataset.messageId

    onMessageDblClick: (event) ->
        url = event.currentTarget.href.split('#')[1]
        window.router.navigate url, {trigger: true}

    onDragStart: (event) ->
        event.stopPropagation()
        data =
            messageID: event.currentTarget.dataset.messageId
            mailboxID: @props.mailboxID
        event.dataTransfer.setData 'text', JSON.stringify(data)
        event.dataTransfer.effectAllowed = 'move'
        event.dataTransfer.dropEffect = 'move'

    getParticipants: (message) ->
        from = message.get 'from'
        to   = message.get('to').concat(message.get('cc'))
        span null,
            Participants participants: from, onAdd: @addAddres
            span null, ', '
            Participants participants: to, onAdd: @addAddress

    addAddress: (address) ->
        ContactActionCreator.createContact address

    _initScroll: ->
        if not @refs.nextPage?
            return

        isVisible = (node, before) ->
            margin = if before then 40 else 0
            rect   = node.getBoundingClientRect()
            height = window.innerHeight or document.documentElement.clientHeight
            width  = window.innerWidth  or document.documentElement.clientWidth
            return rect.bottom <= ( height + 0 ) and rect.top >= 0

        scrollable = @refs.list.getDOMNode().parentNode
        nextNode   = @refs.nextPage.getDOMNode()

        active = document.querySelector("[data-message-id='#{@props.messageID}']")
        if active? and not isVisible(active)
            active.scrollIntoView()

        if not isVisible(nextNode, true)
            loadNext = =>
                if isVisible(nextNode, true)
                    scrollable.removeEventListener 'scroll', loadNext
                    LayoutActionCreator.showMessageList parameters: @props.query
                    #@redirect @props.paginationUrl
                else

            setTimeout ->
                scrollable.addEventListener 'scroll', loadNext
            , 0

    componentDidMount: ->
        @_initScroll()

    componentDidUpdate: ->
        @_initScroll()

module.exports = MessageList

MessagesQuickFilter = React.createClass
    displayName: 'MessagesQuickFilter'

    render: ->
        div
            className: "form-group message-list-action",
            input
                className: "form-control"
                type: "text"
                onBlur: @onQuick

    onQuick: (ev) ->
        LayoutActionCreator.quickFilterMessages ev.target.value.trim()

MessagesFilter = React.createClass
    displayName: 'MessagesFilter'

    mixins: [RouterMixin]

    render: ->
        filter = @props.query.flag
        if not filter? or filter is '-'
            title = t 'list filter'
        else
            title = t 'list filter ' + filter
        div className: 'dropdown filter-dropdown',
            button
                className: 'btn btn-default dropdown-toggle message-list-action'
                type: 'button'
                'data-toggle': 'dropdown'
                title
                    span className: 'caret'
            ul
                className: 'dropdown-menu',
                role: 'menu',
                    li role: 'presentation',
                        a
                            onClick: @onFilter,
                            'data-filter': MessageFilter.ALL,
                            t 'list filter all'
                    li role: 'presentation',
                        a
                            onClick: @onFilter,
                            'data-filter': MessageFilter.UNSEEN,
                            t 'list filter unseen'
                    li role: 'presentation',
                        a
                            onClick: @onFilter,
                            'data-filter': MessageFilter.FLAGGED,
                            t 'list filter flagged'

    onFilter: (ev) ->
        LayoutActionCreator.filterMessages ev.target.dataset.filter

        params = MessageStore.getParams()
        params.accountID = @props.accountID
        params.mailboxID = @props.mailboxID
        LayoutActionCreator.showMessageList parameters: params
        #@redirect @buildUrl
        #    direction: 'first'
        #    action: 'account.mailbox.messages.full'
        #    parameters: params

MessagesSort = React.createClass
    displayName: 'MessagesSort'

    mixins: [RouterMixin]

    render: ->
        sort = @props.query.sort
        if not sort? or sort is '-'
            title = t 'list sort'
        else
            sort  = sort.substr 1
            title = t 'list sort ' + sort
        div className: 'dropdown sort-dropdown',
            button
                className: 'btn btn-default dropdown-toggle message-list-action'
                type: 'button'
                'data-toggle': 'dropdown'
                title
                    span className: 'caret'
            ul
                className: 'dropdown-menu',
                role: 'menu',
                    li role: 'presentation',
                        a
                            onClick: @onSort,
                            'data-sort': 'date',
                            t 'list sort date'
                    li role: 'presentation',
                        a
                            onClick: @onSort,
                            'data-sort': 'subject',
                            t 'list sort subject'

    onSort: (ev) ->
        field = ev.target.dataset.sort

        LayoutActionCreator.sortMessages
            field: field

        params = MessageStore.getParams()
        params.accountID = @props.accountID
        params.mailboxID = @props.mailboxID
        LayoutActionCreator.showMessageList parameters: params
        #@redirect @buildUrl
        #    direction: 'first'
        #    action: 'account.mailbox.messages.full'
        #    parameters: params
