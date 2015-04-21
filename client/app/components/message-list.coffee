{div, ul, li, a, span, i, p, button, input, img} = React.DOM
classer = React.addons.classSet

RouterMixin    = require '../mixins/router_mixin'
TooltipRefresherMixin = require '../mixins/tooltip_refresher_mixin'
DomUtils       = require '../utils/dom_utils'
MessageUtils   = require '../utils/message_utils'
SocketUtils    = require '../utils/socketio_utils'
{MessageFlags, MessageFilter, FlagsConstants, Tooltips} =
    require '../constants/app_constants'

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

    mixins: [RouterMixin, TooltipRefresherMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))
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
        if Object.keys(@state.selected).length > 0
            nbSelected = null
        else
            nbSelected = true

        showList = =>
            params = _.clone(MessageStore.getParams())
            params.accountID = @props.accountID
            params.mailboxID = @props.mailboxID
            LayoutActionCreator.showMessageList parameters: params

        toggleFilterFlag = =>
            if @state.filterFlag
                filter = MessageFilter.ALL
            else
                filter = MessageFilter.FLAGGED
            LayoutActionCreator.filterMessages filter
            showList()
            @setState
                filterFlag:   not @state.filterFlag
                filterUnseen: false
                filterAttach: false

        toggleFilterUnseen = =>
            if @state.filterUnseen
                filter = MessageFilter.ALL
            else
                filter = MessageFilter.UNSEEN
            LayoutActionCreator.filterMessages filter
            showList()
            @setState
                filterUnseen: not @state.filterUnseen
                filterFlag:   false
                filterAttach: false

        toggleFilterAttach = =>
            if @state.filterAttach
                filter = MessageFilter.ALL
            else
                filter = MessageFilter.ATTACH
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

        composeUrl = @buildUrl
            direction: 'first'
            action: 'compose'
            parameters: null
            fullWidth: true

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
                                    className: btnClasses + if @state.filterUnseen then ' shown',
                                    'aria-describedby': Tooltips.FILTER_ONLY_UNREAD
                                    'data-tooltip-direction': 'bottom'
                                    span className: 'fa fa-envelope'
                        if not advanced and not @state.edited
                            div className: btnGrpClasses,
                                button
                                    onClick: toggleFilterFlag
                                    className: btnClasses + if @state.filterFlag then ' shown',
                                    'aria-describedby': Tooltips.FILTER_ONLY_IMPORTANT
                                    'data-tooltip-direction': 'bottom'
                                    span className: 'fa fa-star'
                        if not advanced and not @state.edited
                            div className: btnGrpClasses,
                                button
                                    onClick: toggleFilterAttach
                                    className: btnClasses + if @state.filterAttach then ' shown',
                                    'aria-describedby': Tooltips.FILTER_ONLY_WITH_ATTACHMENT
                                    'data-tooltip-direction': 'bottom'
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
                                            span
                                                className: 'fa fa-refresh'
                                                'aria-describedby': Tooltips.TRIGGER_REFRESH
                                                'data-tooltip-direction': 'bottom'
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
                                    i
                                        className: 'fa fa-cog'
                                        'aria-describedby': Tooltips.ACCOUNT_PARAMETERS
                                        'data-tooltip-direction': 'bottom'
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
                                    className: "#{btnClasses}trash"
                                    type: 'button'
                                    disabled: nbSelected
                                    onClick: @onDelete
                                    'aria-describedby': Tooltips.DELETE_SELECTION
                                    'data-tooltip-direction': 'bottom',
                                        span className: 'fa fa-trash-o'
                        if @state.edited
                            ToolboxMove
                                mailboxes: @props.mailboxes
                                onMove: @onMove
                                direction: 'left'
                        if @state.edited
                            ToolboxActions
                                ref: 'listeToolboxActions'
                                mailboxes: @props.mailboxes
                                onMark: @onMark
                                onConversation: @onConversation
                                onMove: @onConversationMove
                                displayConversations: @props.displayConversations
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

                    a
                        href: composeUrl
                        className: 'menu-item compose-action btn btn-cozy-contrast btn-cozy',
                            i className: 'fa fa-edit'
                            span className: 'item-label', t 'menu compose'


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
                        displayConversations: @props.displayConversations
                        isTrash: @props.isTrash
                        onSelect: (id, val) =>
                            selected = _.clone @state.selected
                            if val
                                selected[id] = val
                            else
                                delete selected[id]
                            if Object.keys(selected).length > 0
                                newState =
                                    edited: true
                                    selected: selected
                            else
                                newState =
                                    allSelected: false
                                    edited: false
                                    selected: {}
                            @setState newState

                    # If message list is filtered, we can't only rely on
                    # message count
                    # So we assume that if query.pageAfter is null, there's
                    # no more messages to display
                    if @moreToSee() and
                       @props.query.pageAfter?
                        p className: 'text-center list-footer',
                            if @props.fetching
                                img
                                    src: 'images/spinner.svg'
                            else
                                a
                                    className: 'more-messages'
                                    onClick: nextPage,
                                    ref: 'nextPage',
                                    t 'list next page'
                    else
                        p ref: 'listEnd', t 'list end'


    # Check if we should display "More messages"
    moreToSee: ->
        nbMessages = parseInt(@props.messagesCount, 10)
        # when displaying conversations, we have to sum the number of messages
        # inside each one to know if we have displayed all messages inside this
        # box
        if @props.displayConversations
            nbInConv   = 0
            @props.messages.map (message) =>
                length = @props.conversationLengths.get(message.get 'conversationID')
                if length?
                    nbInConv += @props.conversationLengths.get(message.get 'conversationID')
            .toJS()

            return nbInConv < nbMessages
        else
            return @props.messages.count() < nbMessages


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

    onDelete: (conv) ->
        selected = Object.keys @state.selected
        if not conv?
            conv = @props.displayConversations
        if selected.length is 0
            alertError t 'list mass no message'
        else
            confirm = @props.settings.get('messageConfirmDelete')
            if confirm
                if conv
                    confirmMessage = t 'list delete conv confirm',
                        smart_count: selected.length
                else
                    confirmMessage = t 'list delete confirm',
                        smart_count: selected.length

            if (not confirm) or
            window.confirm confirmMessage
                MessageUtils.delete selected, conv, =>
                    if selected.length > 0 and @props.messages.count() > 0
                        firstMessageID = @props.messages.first().get('id')
                        MessageActionCreator.setCurrent firstMessageID, true


    onConversationMove: (args) ->
        @onMove args, true

    onMove: (args, conv) ->
        selected = Object.keys @state.selected
        if not conv?
            conv = @props.displayConversations
        if selected.length is 0
            alertError t 'list mass no message'
        else
            newbox = args.target.dataset.value
            MessageUtils.move selected, conv, @props.mailboxID, newbox, =>
                if selected.length > 0 and @props.messages.count() > 0
                    firstMessageID = @props.messages.first().get('id')
                    MessageActionCreator.setCurrent firstMessageID, true

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
                        flags = flags.filter (e) ->
                            return e isnt FlagsConstants.SEEN
                    when FlagsConstants.FLAGGED
                        flags.push MessageFlags.FLAGGED
                    when FlagsConstants.NOFLAG
                        flags = flags.filter (e) ->
                            return e isnt FlagsConstants.FLAGGED
                MessageActionCreator.updateFlag message, flags, (error) ->
                    if error?
                        alertError "#{t("message action mark ko")} #{error}"

    onConversation: (args) ->
        selected = Object.keys @state.selected
        action = args.target.dataset.action
        if action is 'delete'
            @onDelete true
        else
            if selected.length is 0
                alertError t 'list mass no message'
            else
                selected.forEach (id) =>
                    message = @props.messages.get id
                    conversationID = message.get 'conversationID'
                    switch action
                        when 'seen'
                            ConversationActionCreator.seen conversationID, (error) ->
                                if error?
                                    alertError "#{t("conversation seen ko ")} #{error}"
                        when 'unseen'
                            ConversationActionCreator.unseen conversationID, (error) ->
                                if error?
                                    alertError "#{t("conversation unseen ko")} #{error}"
                        when 'flagged'
                            ConversationActionCreator.flag conversationID, (error) ->
                                if error?
                                    alertError "#{t("conversation flagged ko ")} #{error}"
                        when 'noflag'
                            ConversationActionCreator.noflag conversationID, (error) ->
                                if error?
                                    alertError "#{t("conversation noflag ko")} #{error}"

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
        nbMessages = parseInt @props.messagesCount, 10
        if (not @moreToSee()) and @refs.listEnd? and
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
            if @props.displayConversations and cid?
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
                displayConversations: @props.displayConversations
                isTrash: @props.isTrash
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
        # If selected message has changed, scroll the list to put
        # current message into view
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
        shouldUpdate = not _.isEqual(nextState, @state) or
            updatedProps.length > 0

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

        isDraft   = message.get('flags').indexOf(MessageFlags.DRAFT) isnt -1

        if isDraft and not @props.isTrash
            action = 'edit'
            params =
                messageID: message.get 'id'
        else
            conversationID = message.get 'conversationID'
            if conversationID? and @props.displayConversations
                action = 'conversation'
                params =
                    conversationID: conversationID
                    messageID: message.get 'id'
            else
                action = 'message'
                params =
                    messageID: message.get 'id'
        url = @buildUrl
            direction: 'second'
            action: action
            parameters: params
        if not @props.edited
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
            'data-conversation-id': message.get('conversationID')
            draggable: not @props.edited
            onClick: @onMessageClick
            onDragStart: @onDragStart
        ,
            tag
                href: url,
                className: 'wrapper',
                'data-message-id': message.get('id'),
                onClick: @onMessageClick,
                onDoubleClick: @onMessageDblClick,
                ref: 'target',
                    div
                        className: 'avatar-wrapper select-target',
                        input
                            ref: 'select'
                            className: 'select select-target',
                            type: 'checkbox',
                            checked: @props.selected,
                            onChange: @onSelect
                        if avatar?
                            img className: 'avatar', src: avatar
                        else
                            i className: 'fa fa-user'
                    span className: 'participants', @getParticipants message
                    div className: 'preview',
                        if @props.displayConversations and
                           @props.conversationLengths > 1
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
        node = @refs.target.getDOMNode()
        if @props.edited and event.target.classList.contains 'select-target'
            @props.onSelect(not @props.selected)
            event.preventDefault()
            event.stopPropagation()
        else
            if not (event.target.getAttribute('type') is 'checkbox')
                event.preventDefault()
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
        data =
            messageID: event.currentTarget.dataset.messageId
            mailboxID: @props.mailboxID
            conversation: @props.displayConversations
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
