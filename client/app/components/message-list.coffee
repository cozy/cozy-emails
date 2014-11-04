{div, ul, li, a, span, i, p, button, input} = React.DOM
classer = React.addons.classSet

RouterMixin    = require '../mixins/router_mixin'
MessageUtils   = require '../utils/message_utils'
{MessageFlags, MessageFilter} = require '../constants/app_constants'
LayoutActionCreator = require '../actions/layout_action_creator'
MessageStore  = require '../stores/message_store'

MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [RouterMixin]

    render: ->
        messages = @props.messages.map (message, key) =>
            isActive = @props.openMessage? and
                       @props.openMessage.get('id') is message.get('id')
            # @TODO @FIXME Only display initial mail of a thread
            @getMessageRender message, key, isActive
        .toJS()
        nbMessages = parseInt @props.counterMessage, 10
        div className: 'message-list', ref: 'list',
            div className: 'message-list-actions',
                #MessagesQuickFilter {}
                MessagesFilter {query: @props.query}
                MessagesSort {query: @props.query}
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
                                href: @props.buildPaginationUrl(),
                                ref: 'nextPage',
                                t 'list next page'

    getMessageRender: (message, key, isActive) ->
        flags = message.get('flags')
        classes = classer
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
                id     = [conversationID, message.get 'id']
            else
                action = 'message'
                id     = message.get 'id'
        url = @buildUrl
            direction: 'second'
            action: action
            parameters: id

        date = MessageUtils.formatDate message.get 'createdAt'

        li className: 'message ' + classes, key: key,
            a href: url,
                i className: 'fa fa-user'
                span className: 'participants', @getParticipants message
                div className: 'preview',
                    span className: 'title', message.get 'subject'
                    p null, message.get('text').substr(0, 100) + "…"
                span className: 'hour', date
                span className: "flags",
                    i className: 'attach fa fa-paperclip'
                    i className: 'fav fa fa-star'

    getParticipants: (message) ->
        from = MessageUtils.displayAddresses(message.get 'from')
        to   = MessageUtils.displayAddresses(message.get('to')
                .concat(message.get('cc')))
        "#{from}, #{to}"


    _initScroll: ->
        if not @refs.nextPage?
            return

        isVisible = =>
            next   = @refs.nextPage.getDOMNode()
            rect   = next.getBoundingClientRect()
            height = window.innerHeight or document.documentElement.clientHeight
            width  = window.innerWidth  or document.documentElement.clientWidth
            return rect.top >= 0 and
                   rect.left >= 0 and
                   rect.bottom <= height and
                   rect.right <= width

        scrollable = @refs.list.getDOMNode().parentNode

        if not isVisible()
            loadNext = =>
                if isVisible()
                    scrollable.removeEventListener 'scroll', loadNext
                    @redirect @props.buildPaginationUrl()
                else

            scrollable.addEventListener 'scroll', loadNext

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

        @redirect @buildUrl
            direction: 'first'
            action: 'account.mailbox.messages.full'
            parameters: MessageStore.getParams()

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

        @redirect @buildUrl
            direction: 'first'
            action: 'account.mailbox.messages.full'
            parameters: MessageStore.getParams()
