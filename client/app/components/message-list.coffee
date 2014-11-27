{div, ul, li, a, span, i, p, button, input, img} = React.DOM
classer = React.addons.classSet

RouterMixin    = require '../mixins/router_mixin'
MessageUtils   = require '../utils/message_utils'
{MessageFlags, MessageFilter, FlagsConstants} = require '../constants/app_constants'
LayoutActionCreator  = require '../actions/layout_action_creator'
ContactActionCreator = require '../actions/contact_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
MessageStore   = require '../stores/message_store'
MailboxList    = require './mailbox-list'
Participants   = require './participant'
ToolboxActions = require './toolbox_actions'
ToolboxMove    = require './toolbox_move'

alertError   = LayoutActionCreator.alertError
alertSuccess = LayoutActionCreator.alertSuccess

MessageList = React.createClass
    displayName: 'MessageList'

    _selected: {}

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))

    getInitialState: ->
        return {
            edited: false
            loading: false
        }

    componentWillReceiveProps: (props) ->
        @setState loading: false
        if props.mailboxID isnt @props.mailboxID
            @setState edited: false
            @_selected = {}

    render: ->
        compact = @props.settings.get('listStyle') is 'compact'
        messages = @props.messages.map (message, key) =>
            id = message.get('id')
            isActive = @props.messageID is id
            MessageItem
                message: message,
                key: key,
                isActive: isActive,
                edited: @state.edited,
                settings: @props.settings,
                onSelect: (val) =>
                    if val
                        @_selected[id] = val
                    else
                        delete @_selected[id]
                    if Object.keys(@_selected).length > 0
                        @setState edited: true
                    else
                        @setState edited: false

        .toJS()
        nbMessages = parseInt @props.counterMessage, 10
        filterParams =
            accountID: @props.accountID
            mailboxID: @props.mailboxID
            query:     @props.query
        nextPage = =>
            LayoutActionCreator.showMessageList parameters: @props.query

        getMailboxUrl = (mailbox) =>
            @buildUrl
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: [@props.accountID, mailbox.get('id')]

        configMailboxUrl = @buildUrl
            direction: 'first'
            action: 'account.config'
            parameters: @props.accountID
            fullWidth: true

        classList = classer
            compact: compact
            edited: @state.edited
        classCompact = classer
            active: compact
        classEdited = classer
            active: @state.edited
        div className: 'message-list ' + classList, ref: 'list',
            div className: 'message-list-actions',
                #MessagesQuickFilter {}
                div className: 'btn-toolbar', role: 'toolbar',
                    div className: 'btn-group',
                        # Toggle edit
                        div className: 'btn-group btn-group-sm message-list-option',
                            button
                                type: "button"
                                className: "btn btn-default " + classEdited
                                onClick: @toggleEdited,
                                    i className: 'fa fa-square-o'
                        # mailbox-list
                        #if not @state.edited
                            #div className: 'btn-group btn-group-sm message-list-option',
                                #MailboxList
                                    #getUrl: getMailboxUrl
                                    #mailboxes: @props.mailboxes
                                    #selectedMailbox: @props.mailboxID
                        # filters
                        #if not @state.edited
                            #div className: 'btn-group btn-group-sm message-list-option',
                                #MessagesFilter filterParams
                        ## sort
                        #if not @state.edited
                            #div className: 'btn-group btn-group-sm message-list-option',
                                #MessagesSort filterParams
                                #
                        # refresh
                        if not @state.edited
                            div className: 'btn-group btn-group-sm message-list-option',
                                button
                                    className: 'btn btn-default trash',
                                    type: 'button',
                                    onClick: @refresh,
                                        span
                                            className: 'fa fa-refresh'
                        # config
                        if not @state.edited
                            div className: 'btn-group btn-group-sm message-list-option',
                                a
                                    href: configMailboxUrl
                                    className: 'btn btn-default',
                                    i className: 'fa fa-cog'
                        if @state.edited
                            div className: 'btn-group btn-group-sm message-list-option',
                                button
                                    className: 'btn btn-default trash',
                                    type: 'button',
                                    onClick: @onDelete,
                                        span
                                            className: 'fa fa-trash-o'
                        if @state.edited
                            ToolboxMove
                                mailboxes: @props.mailboxes
                                onMove: @onMove
                                direction: 'left'
                        if @state.edited
                            ToolboxActions
                                mailboxes: @props.mailboxes
                                onMark: @onMark
                                onConversation: @onConversation
                                onHeaders: @onHeaders
                                direction: 'left'
            if @props.messages.count() is 0
                p null, @props.emptyListMessage
            else
                div null,
                    #p null, @props.counterMessage
                    ul className: 'list-unstyled',
                        messages
                    if @props.messages.count() < nbMessages
                        p className: 'text-center',
                            if @state.loading
                                i className: "fa fa-refresh fa-spin"
                            else
                                a
                                    #href: @props.paginationUrl
                                    className: 'more-messages'
                                    onClick: nextPage,
                                    ref: 'nextPage',
                                    t 'list next page'
                    else
                        p null, t 'list end'


    refresh: (event) ->
        event.preventDefault()
        LayoutActionCreator.refreshMessages()

    toggleEdited: ->
        @setState edited: not @state.edited

    onDelete: ->
        selected = Object.keys @_selected
        if selected.length is 0
            alertError t 'list mass no message'
        else
            if window.confirm(t 'list delete confirm', nb: selected.length)
                selected.forEach (id) ->
                    MessageActionCreator.delete id, (error) ->
                        if error?
                            alertError "#{t("message action delete ko")} #{error}"

    onMove: (args) ->
        selected = Object.keys @_selected
        if selected.length is 0
            alertError t 'list mass no message'
        else
            newbox = args.target.dataset.value
            if args.target.dataset.conversation?
                selected.forEach (id) =>
                    message = @props.messages.get id
                    conversationID = message.get('conversationID')
                    ConversationActionCreator.move conversationID, newbox, (error) ->
                        if error?
                            alertError "#{t("conversation move ko")} #{error}"
            else
                selected.forEach (id) =>
                    message = @props.messages.get id
                    MessageActionCreator.move message, @props.mailboxID, newbox, (error) ->
                        if error?
                            alertError "#{t("message action move ko")} #{error}"

    onMark: (args) ->
        selected = Object.keys @_selected
        if selected.length is 0
            alertError t 'list mass no message'
        else
            flag = args.target.dataset.value
            selected.forEach (id) =>
                message = @props.messages.get id
                flags = message.get('flags').slice()
                switch flag
                    when FlagsConstants.SEEN
                        flags.push MessageFlags.SEEN
                    when FlagsConstants.UNSEEN
                        flags = flags.filter (e) -> return e isnt FlagsConstants.SEEN
                    when FlagsConstants.FLAGGED
                        flags.push MessageFlags.FLAGGED
                    when FlagsConstants.NOFLAG
                        flags = flags.filter (e) -> return e isnt FlagsConstants.FLAGGED
                MessageActionCreator.updateFlag message, flags, (error) ->
                    if error?
                        alertError "#{t("message action mark ko")} #{error}"

    onConversation: (args) ->
        selected = Object.keys @_selected
        if selected.length is 0
            alertError t 'list mass no message'
        else
            selected.forEach (id) =>
                message = @props.messages.get id
                conversationID = message.get 'conversationID'
                action = args.target.dataset.action
                switch action
                    when 'delete'
                        ConversationActionCreator.delete conversationID(error) ->
                            if error?
                                alertError "#{t("conversation delete ko")} #{error}"
                    when 'seen'
                        ConversationActionCreator.seen conversationID(error) ->
                            if error?
                                alertError "#{t("conversation seen ok ")} #{error}"
                    when 'unseen'
                        ConversationActionCreator.unseen conversationID(error) ->
                            if error?
                                alertError "#{t("conversation unseen ok")} #{error}"

    _isVisible: (node, before) ->
        margin = if before then 40 else 0
        rect   = node.getBoundingClientRect()
        height = window.innerHeight or document.documentElement.clientHeight
        width  = window.innerWidth  or document.documentElement.clientWidth
        return rect.bottom <= ( height + 0 ) and rect.top >= 0

    _loadNext: ->
        if @refs.nextPage? and @_isVisible(@refs.nextPage.getDOMNode(), true)
            @setState loading: true
            LayoutActionCreator.showMessageList parameters: @props.query

    _initScroll: ->
        if not @refs.nextPage?
            return

        # scroll current message into view
        active = document.querySelector("[data-message-id='#{@props.messageID}']")
        if active? and not @_isVisible(active)
            active.scrollIntoView()

        # listen to scroll events
        scrollable = @refs.list.getDOMNode().parentNode
        setTimeout =>
            scrollable.removeEventListener 'scroll', @_loadNext
            scrollable.addEventListener 'scroll', @_loadNext
        , 0

    componentDidMount: ->
        @_initScroll()

    componentDidUpdate: ->
        @_initScroll()

    componentWillUnmount: ->
        scrollable = @refs.list.getDOMNode().parentNode
        scrollable.removeEventListener 'scroll', @_loadNext

module.exports = MessageList

MessageItem = React.createClass
    displayName: 'MessagesItem'

    mixins: [RouterMixin]

    getInitialState: ->
        return {
            selected: @props.message.get('selected') is true
        }

    render: ->
        message = @props.message
        flags = message.get('flags')
        classes = classer
            message: true
            read: message.get 'isRead'
            active: @props.isActive
            edited: @props.edited
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
        if not @props.edited
            url = @buildUrl
                direction: 'second'
                action: action
                parameters: id
            tag = a
        else
            tag = span

        compact = @props.settings.get('listStyle') is 'compact'
        date    = MessageUtils.formatDate message.get('createdAt'), compact
        avatar  = MessageUtils.getAvatar message

        li
            className: classes
            key: @props.key
            'data-message-id': message.get('id')
            draggable: not @props.edited
            onClick: @onMessageClick
            onDragStart: @onDragStart
        ,
            tag
                href: url,
                'data-message-id': message.get('id'),
                onClick: @onMessageClick,
                onDoubleClick: @onMessageDblClick,
                    input
                        className: 'select',
                        type: 'checkbox',
                        checked: @state.selected
                        onChange: @onSelect
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

    onSelect: (e) ->
        @props.onSelect(not @state.selected)
        @setState selected: not @state.selected

    onMessageClick: (event) ->
        if @props.edited
            @onSelect event
        else
            if not @props.settings.get('displayPreview')
                event.preventDefault()
                MessageActionCreator.setCurrent event.currentTarget.dataset.messageId

    onMessageDblClick: (event) ->
        if not @props.edited
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
            Participants participants: from, onAdd: @addAddress
            span null, ', '
            Participants participants: to, onAdd: @addAddress

    addAddress: (address) ->
        ContactActionCreator.createContact address

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
            title = i className: 'fa fa-filter'
        else
            title = t 'list filter ' + filter
        div className: 'btn-group btn-group-sm dropdown filter-dropdown',
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
        div className: 'btn-group btn-group-sm dropdown sort-dropdown',
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
