{div, ul, li, a, span, i, p, button, input} = React.DOM
classer = React.addons.classSet

RouterMixin    = require '../mixins/router_mixin'
MessageUtils   = require '../utils/message_utils'
{MessageFlags, MessageFilter} = require '../constants/app_constants'
LayoutActionCreator = require '../actions/layout_action_creator'

MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not Immutable.is(nextProps.messages, @props.messages) or
               not Immutable.is(nextProps.openMessage, @props.openMessage)

    render: ->
        curPage = parseInt @props.pageNum, 10
        nbPages = Math.ceil(@props.messagesCount / @props.messagesPerPage)
        div className: 'message-list',
            div className: 'message-list-actions',
                MessagesQuickFilter {}
                MessagesFilter {}
                MessagesSort {}
            if @props.messages.count() is 0
                p null, @props.emptyListMessage
            else
                div null,
                    @getPagerRender curPage, nbPages
                    p null, @props.counterMessage
                    ul className: 'list-unstyled',
                        @props.messages.map (message, key) =>
                            # only displays initial email of a thread
                            if true # @FIXME Mage conversation # message.get('inReplyTo').length is 0
                                isActive = @props.openMessage? and
                                           @props.openMessage.get('id') is message.get('id')
                                @getMessageRender message, key, isActive
                        .toJS()
                    @getPagerRender curPage, nbPages

    getMessageRender: (message, key, isActive) ->
        classes = classer
            read: message.get 'isRead'
            active: isActive
            'unseen': message.get('flags').indexOf(MessageFlags.SEEN) is -1
            'has-attachments': message.get 'hasAttachments'
            'is-fav': message.get('flags').indexOf(MessageFlags.FLAGGED) isnt -1

        isDraft = message.get('flags').indexOf(MessageFlags.DRAFT) isnt -1

        url = @buildUrl
            direction: 'second'
            action: if isDraft then 'compose' else 'message'
            parameters: message.get 'id'

        date = MessageUtils.formatDate message.get 'createdAt'

        li className: 'message ' + classes, key: key,
            a href: url,
                i className: 'fa fa-user'
                span className: 'participants', @getParticipants message
                div className: 'preview',
                    span className: 'title', message.get 'subject'
                    p null, message.get 'text'
                span className: 'hour', date
                span className: "flags",
                    i className: 'attach fa fa-paperclip'
                    i className: 'fav fa fa-star'

    getPagerRender: (curPage, nbPages) ->
        if nbPages < 2
            return
        classFirst = if curPage is 1 then 'disabled' else ''
        classLast  = if curPage is nbPages then 'disabled' else ''
        if nbPages < 11
            minPage = 1
            maxPage = nbPages
        else
            minPage = if curPage < 5 then 1 else curPage - 2
            maxPage = minPage + 4
            if maxPage > nbPages
                maxPage = nbPages

        urlFirst = @props.buildPaginationUrl 1
        urlLast = @props.buildPaginationUrl nbPages

        div className: 'pagination-box',
            ul className: 'pagination',
                li className: classFirst,
                    a href: urlFirst, '«'
                if minPage > 1
                    li className: 'disabled',
                        a href: urlFirst, '…'
                for j in [minPage..maxPage] by 1
                    classCurr = if j is curPage then 'current' else ''
                    urlCurr = @props.buildPaginationUrl j
                    li className: classCurr, key: j,
                        a href: urlCurr, j
                if maxPage < nbPages
                    li className: 'disabled',
                        a href: urlFirst, '…'
                li className: classLast,
                    a href: urlLast, '»'

    getParticipants: (message) -> "#{MessageUtils.displayAddresses(message.get 'from')}, #{MessageUtils.displayAddresses(message.get('to').concat(message.get('cc')))}"

module.exports = MessageList

MessagesQuickFilter = React.createClass
    displayName: 'MessagesQuickFilter'

    render: ->
        div
            className: "form-group pull-left message-list-action",
            input
                className: "form-control"
                type: "text"
                onBlur: @onQuick

    onQuick: (ev) ->
        LayoutActionCreator.quickFilterMessages ev.target.value.trim()

MessagesFilter = React.createClass
    displayName: 'MessagesFilter'

    render: ->
        div className: 'dropdown pull-left filter-dropdown',
            button
                className: 'btn btn-default dropdown-toggle message-list-action',
                type: 'button',
                'data-toggle': 'dropdown',
                t 'list filter',
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

MessagesSort = React.createClass
    displayName: 'MessagesSort'

    getInitialState: ->
        return {
            field: "date",
            order: -1
        }

    render: ->
        div className: 'dropdown pull-left sort-dropdown',
            button
                className: 'btn btn-default dropdown-toggle message-list-action',
                type: 'button',
                'data-toggle': 'dropdown',
                t 'list sort',
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
        order = if field is @state.field then -1 * @state.order else 1

        LayoutActionCreator.sortMessages
            field: field
            order: order

        @setState field: field, order: order
