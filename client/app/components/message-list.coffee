{div, ul, li, a, span, i, p, button, input, img} = React.DOM
classer = React.addons.classSet

RouterMixin    = require '../mixins/router_mixin'
DomUtils       = require '../utils/dom_utils'
MessageUtils   = require '../utils/message_utils'
SocketUtils    = require '../utils/socketio_utils'
{MessageFlags, MessageFilter, FlagsConstants} = require '../constants/app_constants'

AccountActionCreator      = require '../actions/account_action_creator'
ContactActionCreator      = require '../actions/contact_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
LayoutActionCreator       = require '../actions/layout_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'

MessageStore   = require '../stores/message_store'

MailboxList    = require './mailbox-list'
Participants   = require './participant'
ToolboxActions = require './toolbox_actions'
ToolboxMove    = require './toolbox_move'

alertError   = LayoutActionCreator.alertError

MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or not (_.isEqual(nextProps, @props))
        return should

    getInitialState: ->
        edited: false
        filterFlag: false
        filterUnsead: false
        filterAttach: false
        selected: {}
        allSelected: false

    componentWillReceiveProps: (props) ->
        if props.mailboxID isnt @props.mailboxID
            @setState allSelected: false, edited: false, selected: {}
        else
            selected = @state.selected
            Object.keys(selected).forEach (id) ->
                if not props.messages.get(id)
                    delete selected[id]
            @setState selected: selected
            if Object.keys(selected).length is 0
                @setState allSelected: false, edited: false

    render: ->
        compact = @props.settings.get('listStyle') is 'compact'
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
                parameters: [@props.accountID, mailbox.id]

        configMailboxUrl = @buildUrl
            direction: 'first'
            action: 'account.config'
            parameters: [@props.accountID, 'account']
            fullWidth: true

        advanced   = @props.settings.get('advanced')
        nbSelected = if Object.keys(@state.selected).length > 0 then null else true

        showList = =>
            params = _.clone(MessageStore.getParams())
            params.accountID = @props.accountID
            params.mailboxID = @props.mailboxID
            LayoutActionCreator.showMessageList parameters: params

        toggleFilterFlag = =>
            filter = if @state.filterFlag then MessageFilter.ALL else MessageFilter.FLAGGED
            LayoutActionCreator.filterMessages filter
            showList()
            @setState
                filterFlag:   not @state.filterFlag
                filterUnseen: false
                filterAttach: false

        toggleFilterUnseen = =>
            filter = if @state.filterUnseen then MessageFilter.ALL else MessageFilter.UNSEEN
            LayoutActionCreator.filterMessages filter
            showList()
            @setState
                filterUnseen: not @state.filterUnseen
                filterFlag:   false
                filterAttach: false

        toggleFilterAttach = =>
            filter = if @state.filterAttach then MessageFilter.ALL else MessageFilter.ATTACH
            LayoutActionCreator.filterMessages filter
            showList()
            @setState
                filterAttach: not @state.filterAttach
                filterFlag:   false
                filterUnseen: false

        classList = classer
            compact: compact
            edited: @state.edited
        classCompact = classer
            active: compact
        classEdited = classer
            active: @state.edited

        btnClasses    = 'btn btn-default '
        btnGrpClasses = 'btn-group btn-group-sm message-list-option '

        div
            className: 'message-list ' + classList,
            ref: 'list',
            'data-mailbox-id': @props.mailboxID,
            div className: 'message-list-actions',
                #if advanced and not @state.edited
                #    MessagesQuickFilter {}
                div className: 'btn-toolbar', role: 'toolbar',
                    div className: 'btn-group',
                        # Toggle edit
                        if advanced
                            div className: btnGrpClasses,
                                button
                                    type: "button"
                                    className: btnClasses + classEdited
                                    onClick: @toggleEdited,
                                        i className: 'fa fa-square-o'
                        # mailbox-list
                        if advanced and not @state.edited
                            div className: btnGrpClasses,
                                MailboxList
                                    getUrl: getMailboxUrl
                                    mailboxes: @props.mailboxes
                                    selectedMailboxID: @props.mailboxID

                        # Responsive menu button
                        if not advanced and not @state.edited
                            div className: btnGrpClasses + ' toggle-menu-button',
                                button
                                    onClick: @props.toggleMenu
                                    title: t 'menu toggle'
                                    className: btnClasses,
                                    span className: 'fa fa-inbox'

                        # filters
                        if not advanced and not @state.edited
                            div className: btnGrpClasses,
                                button
                                    onClick: toggleFilterUnseen
                                    title: t 'list filter unseen title'
                                    className: btnClasses + if @state.filterUnseen then ' shown',
                                    span className: 'fa fa-envelope'
                        if not advanced and not @state.edited
                            div className: btnGrpClasses,
                                button
                                    onClick: toggleFilterFlag
                                    title: t 'list filter flagged title'
                                    className: btnClasses + if @state.filterFlag then ' shown',
                                    span className: 'fa fa-star'
                        if not advanced and not @state.edited
                            div className: btnGrpClasses,
                                button
                                    onClick: toggleFilterAttach
                                    title: t 'list filter attach title'
                                    className: btnClasses + if @state.filterAttach then ' shown',
                                    span className: 'fa fa-paperclip'
                        if advanced and not @state.edited
                            div className: btnGrpClasses,
                                MessagesFilter filterParams
                        ## sort
                        if advanced and not @state.edited
                            div className: btnGrpClasses,
                                MessagesSort filterParams

                        # refresh
                        if not @state.edited
                            div className: btnGrpClasses,
                                if @props.refreshes.length is 0
                                    button
                                        className: btnClasses,
                                        type: 'button',
                                        disabled: null,
                                        onClick: @refresh,
                                            span className: 'fa fa-refresh'
                                else
                                    img
                                        src: 'images/spinner.svg'
                                        alt: 'spinner'
                                        className: 'spin'
                        # config
                        if not @state.edited
                            div className: btnGrpClasses,
                                a
                                    href: configMailboxUrl
                                    className: btnClasses + 'mailbox-config',
                                    i className: 'fa fa-cog'
                        if @state.edited
                            div className: btnGrpClasses,
                                button
                                    type: "button"
                                    className: btnClasses + classEdited
                                    onClick: @toggleAll,
                                        i className: 'fa fa-square-o'
                        if @state.edited
                            div className: btnGrpClasses,
                                button
                                    className: btnClasses + 'trash',
                                    type: 'button',
                                    disabled: nbSelected
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

                        if @props.isTrash and not @state.edited
                            div className: btnGrpClasses,
                                button
                                    className: btnClasses,
                                    type: 'button',
                                    disabled: null,
                                    onClick: @expungeMailbox,
                                        span
                                            className: 'fa fa-recycle'

            if @props.messages.count() is 0
                if @props.fetching
                    p null, t 'list fetching'
                else
                    p null, @props.emptyListMessage
            else
                div null,
                    #p null, @props.counterMessage
                    MessageListBody
                        messages: @props.messages
                        settings: @props.settings
                        mailboxID: @props.mailboxID
                        messageID: @props.messageID
                        conversationID: @props.conversationID
                        conversationLengths: @props.conversationLengths
                        login: @props.login
                        edited: @state.edited
                        selected: @state.selected
                        allSelected: @state.allSelected
                        onSelect: (id, val) =>
                            selected = _.clone @state.selected
                            if val
                                selected[id] = val
                            else
                                delete selected[id]
                            if Object.keys(selected).length > 0
                                @setState edited: true, selected: selected
                            else
                                @setState allSelected: false, edited: false, selected: {}

                    # If message list is filtered, we can't only rely on message count
                    # So we assume that if query.pageAfter is null, there's no more
                    # messages to display
                    if @props.messages.count() < parseInt(@props.counterMessage, 10) and
                       @props.query.pageAfter?
                        p className: 'text-center list-footer',
                            if @props.fetching
                                i className: "fa fa-refresh fa-spin"
                            else
                                a
                                    className: 'more-messages'
                                    onClick: nextPage,
                                    ref: 'nextPage',
                                    t 'list next page'
                    else
                        p ref: 'listEnd', t 'list end'


    refresh: (event) ->
        event.preventDefault()
        LayoutActionCreator.refreshMessages()

    toggleEdited: ->
        if @state.edited
            @setState allSelected: false, edited: false, selected: {}
        else
            @setState edited: true

    toggleAll: ->
        if @state.allSelected
            @setState allSelected: false, edited: false, selected: {}
        else
            selected = {}
            @props.messages.map (message, key) ->
                selected[key] = true
            .toJS()
            @setState allSelected: true, edited: true, selected: selected

    onDelete: ->
        selected = Object.keys @state.selected
        settings = @props.settings
        if selected.length is 0
            alertError t 'list mass no message'
        else
            MessageUtils.delete selected, settings.get 'displayConversation',
                settings.get 'messageConfirmDelete'

    onMove: (args) ->
        selected = Object.keys @state.selected
        if selected.length is 0
            alertError t 'list mass no message'
        else
            newbox = args.target.dataset.value
            if args.target.dataset.conversation? or
               @props.settings.get 'displayConversation'
                selected.forEach (id) =>
                    message = @props.messages.get id
                    ConversationActionCreator.move message, @props.mailboxID, newbox, (error) ->
                        if error?
                            alertError "#{t("conversation move ko")} #{error}"
                        else
                            window.cozyMails.messageNavigate()
            else
                selected.forEach (id) =>
                    message = @props.messages.get id
                    MessageActionCreator.move message, @props.mailboxID, newbox, (error) ->
                        if error?
                            alertError "#{t("message action move ko")} #{error}"
                        else
                            window.cozyMails.messageNavigate()

    onMark: (args) ->
        selected = Object.keys @state.selected
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
        selected = Object.keys @state.selected
        if selected.length is 0
            alertError t 'list mass no message'
        else
            selected.forEach (id) =>
                message = @props.messages.get id
                conversationID = message.get 'conversationID'
                action = args.target.dataset.action
                switch action
                    when 'delete'
                        ConversationActionCreator.delete conversationID, (error) ->
                            if error?
                                alertError "#{t("conversation delete ko")} #{error}"
                    when 'seen'
                        ConversationActionCreator.seen conversationID, (error) ->
                            if error?
                                alertError "#{t("conversation seen ko ")} #{error}"
                    when 'unseen'
                        ConversationActionCreator.unseen conversationID, (error) ->
                            if error?
                                alertError "#{t("conversation unseen ko")} #{error}"

    expungeMailbox: (e) ->
        e.preventDefault()

        if window.confirm(t 'account confirm delbox')
            mailbox =
                mailboxID: @props.mailboxID
                accountID: @props.accountID

            AccountActionCreator.mailboxExpunge mailbox, (error) =>

                if error?
                    # if user hasn't switched to another box, refresh display
                    if @props.accountID is mailbox.accountID and
                       @props.mailboxID is mailbox.mailboxID
                        params = _.clone(MessageStore.getParams())
                        params.accountID = @props.accountID
                        params.mailboxID = @props.mailboxID
                        LayoutActionCreator.showMessageList parameters: params

                    LayoutActionCreator.alertError "#{t("mailbox expunge ko")} #{error}"
                else
                    LayoutActionCreator.notify t("mailbox expunge ok"),
                        autoclose: true

    _loadNext: ->
        if @refs.nextPage? and DomUtils.isVisible(@refs.nextPage.getDOMNode())
            LayoutActionCreator.showMessageList parameters: @props.query

    _handleRealtimeGrowth: ->
        nbMessages = parseInt @props.counterMessage, 10
        if nbMessages < @props.messages.count() and @refs.listEnd? and
        not DomUtils.isVisible(@refs.listEnd.getDOMNode())
            lastdate = @props.messages.last().get('date')
            SocketUtils.changeRealtimeScope @props.mailboxID, lastdate

    _initScroll: ->
        if not @refs.nextPage?
            return

        # listen to scroll events
        scrollable = @refs.list.getDOMNode().parentNode
        setTimeout =>
            scrollable.removeEventListener 'scroll', @_loadNext
            scrollable.addEventListener 'scroll', @_loadNext
            @_loadNext()
            # a lot of event can make the "more messages" label visible,
            # so we check every few seconds
            if not @_checkNextInterval?
                @_checkNextInterval = window.setInterval @_loadNext, 10000
        , 0

    componentDidMount: ->
        @_initScroll()

    componentDidUpdate: ->
        @_initScroll()

        @_handleRealtimeGrowth()

    componentWillUnmount: ->
        scrollable = @refs.list.getDOMNode().parentNode
        scrollable.removeEventListener 'scroll', @_loadNext
        if @_checkNextInterval?
            window.clearInterval @_checkNextInterval

module.exports = MessageList

MessageListBody = React.createClass
    displayName: 'MessageListBody'

    getInitialState: ->
        state =
            messageID: null

    shouldComponentUpdate: (nextProps, nextState) ->
        # we must do the comparison manually because the property "onSelect" is
        # a function (therefore it should not be compared)
        updatedProps = Object.keys(nextProps).filter (prop) =>
            return typeof nextProps[prop] isnt 'function' and
                not (_.isEqual(nextProps[prop], @props[prop]))
        should = not(_.isEqual(nextState, @state)) or updatedProps.length > 0

        return should

    render: ->
        messages = @props.messages.map (message, key) =>
            id = message.get('id')
            cid = message.get('conversationID')
            if @props.settings.get('displayConversation')
                isActive = @props.conversationID is cid
            else
                isActive = @props.messageID is id
            MessageItem
                message: message,
                mailboxID: @props.mailboxID,
                conversationLengths: @props.conversationLengths?.get(cid),
                key: key,
                isActive: isActive,
                edited: @props.edited,
                settings: @props.settings,
                selected: @props.selected[id]?,
                login: @props.login
                onSelect: (val) =>
                    @props.onSelect id, val

        .toJS()
        ul className: 'list-unstyled',
            messages

    componentDidMount: ->
        @_onMount()

    componentDidUpdate: ->
        @_onMount()

    _onMount: ->
        # If selected message has changed, scroll the list to put current message
        # into view
        if @state.messageID isnt @props.messageID
            active = document.querySelector("[data-message-id='#{@props.messageID}']")
            if active? and not DomUtils.isVisible(active)
                active.scrollIntoView(false)
            @setState messageID: @props.messageID

MessageItem = React.createClass
    displayName: 'MessagesItem'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        # we must do the comparison manually because the property "onSelect" is
        # a function (therefore it should not be compared)
        updatedProps = Object.keys(nextProps).filter (prop) =>
            return typeof nextProps[prop] isnt 'function' and
                not (_.isEqual(nextProps[prop], @props[prop]))
        shouldUpdate = not _.isEqual(nextState, @state) or updatedProps.length > 0

        return shouldUpdate

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
            params =
                messageID: message.get 'id'
        else
            conversationID = message.get 'conversationID'
            if conversationID and @props.settings.get('displayConversation')
                action = 'conversation'
                params =
                    conversationID: conversationID
                    messageID: message.get 'id'
            else
                action = 'message'
                params =
                    conversationID: conversationID
                    messageID: message.get 'id'
        if not @props.edited
            url = @buildUrl
                direction: 'second'
                action: action
                parameters: params
            tag = a
        else
            tag = span

        compact = @props.settings.get('listStyle') is 'compact'
        date    = MessageUtils.formatDate message.get('createdAt'), compact
        avatar  = MessageUtils.getAvatar message
        text    = message.get('text')
        preview = if text? then text.substr(0, 100) + "…" else ''

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
                className: 'wrapper'
                'data-message-id': message.get('id'),
                onClick: @onMessageClick,
                onDoubleClick: @onMessageDblClick,
                ref: 'target',
                    div
                        className: 'avatar-wrapper',
                        input
                            ref: 'select'
                            className: 'select',
                            type: 'checkbox',
                            checked: @props.selected,
                            onChange: @onSelect
                        if avatar?
                            img className: 'avatar', src: avatar
                        else
                            i className: 'fa fa-user'
                    span className: 'participants', @getParticipants message
                    div className: 'preview',
                        if @props.conversationLengths > 1
                            span className: 'badge conversation-length',
                                @props.conversationLengths
                        span className: 'title',
                            message.get 'subject'
                        p null, preview
                    span className: 'hour', date
                    span className: "flags",
                        i className: 'attach fa fa-paperclip'
                        i className: 'fav fa fa-star'

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
    componentDidMount: ->
        @_doCheck()
    componentDidUpdate: ->
        @_doCheck()
    onSelect: (e) ->
        @props.onSelect(not @props.selected)
        e.preventDefault()
        e.stopPropagation()

    onMessageClick: (event) ->
        if @props.edited
            @props.onSelect(not @props.selected)
            event.preventDefault()
            event.stopPropagation()
        else
            if not (event.target.getAttribute('type') is 'checkbox')
                event.preventDefault()
                node = @refs.target.getDOMNode()
                MessageActionCreator.setCurrent node.dataset.messageId
                if @props.settings.get('displayPreview')
                    href = '#' + node.href.split('#')[1]
                    @redirect href

    onMessageDblClick: (event) ->
        if not @props.edited
            url = event.currentTarget.href.split('#')[1]
            window.router.navigate url, {trigger: true}

    onDragStart: (event) ->
        event.stopPropagation()
        data =
            messageID: event.currentTarget.dataset.messageId
            mailboxID: @props.mailboxID
            conversation: @props.settings.get 'displayConversation'
        event.dataTransfer.setData 'text', JSON.stringify(data)
        event.dataTransfer.effectAllowed = 'move'
        event.dataTransfer.dropEffect = 'move'

    getParticipants: (message) ->
        from = message.get 'from'
        to   = message.get('to').concat(message.get('cc')).filter (address) =>
            return address.address isnt @props.login and
                address.address isnt from[0]?.address
        separator = if to.length > 0 then ', ' else ' '
        span null,
            Participants participants: from, onAdd: @addAddress
            span null, separator
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
                    li role: 'presentation',
                        a
                            onClick: @onFilter,
                            'data-filter': MessageFilter.ATTACH,
                            t 'list filter attach'

    onFilter: (ev) ->
        LayoutActionCreator.filterMessages ev.target.dataset.filter

        params = _.clone(MessageStore.getParams())
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

        params = _.clone(MessageStore.getParams())
        params.accountID = @props.accountID
        params.mailboxID = @props.mailboxID
        LayoutActionCreator.showMessageList parameters: params
        #@redirect @buildUrl
        #    direction: 'first'
        #    action: 'account.mailbox.messages.full'
        #    parameters: params
