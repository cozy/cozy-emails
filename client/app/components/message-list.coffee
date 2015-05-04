{div, ul, li, a, span, i, p, button, input, img, form} = React.DOM
classer = React.addons.classSet

RouterMixin    = require '../mixins/router_mixin'
TooltipRefresherMixin = require '../mixins/tooltip_refresher_mixin'
DomUtils       = require '../utils/dom_utils'
MessageUtils   = require '../utils/message_utils'
SocketUtils    = require '../utils/socketio_utils'
{MessageFlags, MessageFilter, Tooltips} =
    require '../constants/app_constants'

AccountActionCreator      = require '../actions/account_action_creator'
ContactActionCreator      = require '../actions/contact_action_creator'
LayoutActionCreator       = require '../actions/layout_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'

MessageStore   = require '../stores/message_store'

{Dropdown}     = require './basic_components'
MailboxList    = require './mailbox_list'
Participants   = require './participant'
{Spinner}      = require './basic_components'
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
        quickFilters: false
        selected: {}
        allSelected: false

    componentWillReceiveProps: (props) ->
        if props.mailboxID isnt @props.mailboxID
            @setState allSelected: false, edited: false, selected: {}
        else
            selected = @state.selected
            # remove selected messages that are not in view anymore
            for id, isSelected of selected when not props.messages.get(id)
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
                quickFilters: false

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
                quickFilters: false

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
                quickFilters: false

        toggleQuickFilter = =>
            if @state.quickFilters
                # default sort
                LayoutActionCreator.sortMessages
                    order: '-'
                    field: 'date'
                showList()

            @setState
                filterFlag:   false
                filterUnseen: false
                filterAttach: false
                quickFilters: not @state.quickFilters

        classList = classer
            compact: compact
            edited: @state.edited
        classCompact = classer
            active: compact
        classEdited = classer
            active: @state.edited

        btnClasses    = 'btn btn-default '
        btnGrpClasses = 'btn-group btn-group-sm message-list-option '
        getFilterClass = (filter) ->
            shown = if filter then ' shown' else ''
            return "#{btnClasses}#{shown}"

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
                                    ref: 'mailboxList'

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
                                    className: getFilterClass @state.filterUnseen
                                    'aria-describedby': Tooltips.FILTER_ONLY_UNREAD
                                    'data-tooltip-direction': 'bottom'
                                    span className: 'fa fa-envelope'
                        if not advanced and not @state.edited
                            div className: btnGrpClasses,
                                button
                                    onClick: toggleFilterFlag
                                    className: getFilterClass @state.filterFlag
                                    'aria-describedby': Tooltips.FILTER_ONLY_IMPORTANT
                                    'data-tooltip-direction': 'bottom'
                                    span className: 'fa fa-star'
                        if not advanced and not @state.edited
                            div className: btnGrpClasses,
                                button
                                    onClick: toggleFilterAttach
                                    className: getFilterClass @state.filterAttach
                                    'aria-describedby': Tooltips.FILTER_ONLY_WITH_ATTACHMENT
                                    'data-tooltip-direction': 'bottom'
                                    span className: 'fa fa-paperclip'
                        if not advanced and not @state.edited
                            div className: btnGrpClasses,
                                button
                                    onClick: toggleQuickFilter
                                    className: getFilterClass @state.quickFilters
                                    'aria-describedby': Tooltips.QUICK_FILTER
                                    'data-tooltip-direction': 'bottom'
                                    span className: 'fa fa-filter'
                        ## sort
                        if advanced and not @state.edited
                            div className: btnGrpClasses,
                                MessagesSort filterParams

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
                        if @state.edited and not @props.displayConversations
                            ToolboxMove
                                ref: 'listToolboxMove'
                                mailboxes: @props.mailboxes
                                onMove: @onMove
                                direction: 'left'
                        if @state.edited
                            ToolboxActions
                                ref: 'listToolboxActions'
                                mailboxes: @props.mailboxes
                                onMark: @onMark
                                onConversationDelete: @onConversationDelete
                                onConversationMark: @onConversationMark
                                onConversationMove: @onConversationMove
                                displayConversations: @props.displayConversations
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

            if @state.quickFilters
                div className: 'message-list-filters form-horizontal',
                    MessagesQuickFilter
                        accountID: @props.accountID
                        mailboxID: @props.mailboxID

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
                        ref: 'listBody'
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

                    if @props.query.pageAfter isnt '-'
                        p className: 'text-center list-footer',
                            if @props.fetching
                                Spinner()
                            else
                                a
                                    className: 'more-messages'
                                    onClick: nextPage,
                                    ref: 'nextPage',
                                    t 'list next page'
                    else
                        p ref: 'listEnd', t 'list end'


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

    _getSelectedAndMode: (applyToConversation) ->
        selected = Object.keys @state.selected
        count = selected.length
        applyToConversation = Boolean applyToConversation
        applyToConversation ?= @props.displayConversations
        if selected.length is 0
            alertError t 'list mass no message'
            return false

        else if not applyToConversation
            return {cout, messageIDs: selected, applyToConversation}

        else
            conversationIDs = selected.map (id) =>
                @props.messages.get(id).get('conversationID')

            return {count, conversationIDs, applyToConversation}

    onConversationDelete: ->
        @onDelete true

    onDelete: (applyToConversation) ->
        return unless options = @_getSelectedAndMode(applyToConversation)

        if options.applyToConversation
            msg = t 'list delete conv confirm', smart_count: options.count
        else
            msg = t 'list delete confirm', smart_count: options.count

        noConfirm = not @props.settings.get('messageConfirmDelete')
        if noConfirm or window.confirm msg
            MessageActionCreator.delete options, =>
                if options.count > 0 and @props.messages.count() > 0
                    firstMessageID = @props.messages.first().get('id')
                    MessageActionCreator.setCurrent firstMessageID, true



    onConversationMove: (to) ->
        @onMove to, true

    onMove: (to, applyToConversation) ->
        return unless options = @_getSelectedAndMode(applyToConversation)

        from = @props.mailboxID

        MessageActionCreator.move options, from, to, =>
            if options.count > 0 and @props.messages.count() > 0
                firstMessageID = @props.messages.first().get('id')
                MessageActionCreator.setCurrent firstMessageID, true


    onConversationMark: (flag) ->
        @onMark flag, true

    onMark: (flag, applyToConversation) ->
        return unless options = @_getSelectedAndMode(applyToConversation)

        MessageActionCreator.mark options, flag

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
        if @props.pageAfter isnt '-' and
           @refs.listEnd? and
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
                ref: 'messageItem'
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
        span null,
            Participants
                participants: from
                onAdd: @addAddress
                ref: 'from'
            span null, separator
            Participants
                participants: to
                onAdd: @addAddress
                ref: 'to'

    addAddress: (address) ->
        ContactActionCreator.createContact address


MessagesQuickFilter = React.createClass
    displayName: 'MessagesQuickFilter'

    getInitialState: ->
        # default filter type: date
        state =
            type: 'date'
            startValid: true # valid start date
            endValid: true   # valid end date
        return state

    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))
        return should

    render: ->

        filters = {}
        ['from', 'dest', 'date'].map (filter) ->
            filters[filter] = t "list filter #{filter}"

        startClass = 'error' if not @state.startValid
        endClass   = 'error' if not @state.endValid

        form className: 'list-filters',
            # Filter type
            Dropdown
                value: @state.type
                values: filters
                onChange: @onChange
            if @state.type is 'date'
                span null,
                    input
                        ref: 'dateStart'
                        id: 'filterDateStart'
                        key: 'filterDateStart'
                        name: 'filterDateStart'
                        className: "filter-date #{startClass or ''}"
                        placeholder: t 'list filter date placeholder'
                        onBlur: @doValidate
                        type: "text",
                    input
                        ref: 'dateEnd'
                        id: 'filterDateEnd'
                        key: 'filterDateEnd'
                        name: 'filterDateEnd'
                        className: "filter-date #{endClass or ''}"
                        placeholder: t 'list filter date placeholder'
                        onBlur: @doValidate
                        type: "text"
            else
                input
                    ref: 'value'
                    className: ""
                    type: "text"
                    onKeyDown: @onKeyDown
            button
                onClick: @onFilter
                className: 'btn btn-default'
                'aria-describedby': Tooltips.FILTER
                'data-tooltip-direction': 'bottom',
                    span className: 'fa fa-filter'

    # Add third party datepicker to start and end date fields
    initDatepicker: ->
        if @state.type is 'date'
            datePickerController.setDebug true
            options =
                formElements:
                    filterDateStart: '%d/%m/%Y'
            datePickerController.createDatePicker options
            options =
                formElements:
                    filterDateEnd: '%d/%m/%Y'
            datePickerController.createDatePicker options
        else
            datePickerController.destroyDatePicker 'filterDateStart'
            datePickerController.destroyDatePicker 'filterDateEnd'

    componentDidMount: ->
        @initDatepicker()

    componentDidUpdate: ->
        @initDatepicker()

    # Return start date in ISO 8601 compliant format
    _getStartDate: ->
        start = @refs.dateStart.getDOMNode().value.trim()
        if start is ''
            return ''
        else
            start = start.split '/'
            return "#{start[2]}-#{start[1]}-#{start[0]}T00:00:00.000Z"

    # Return end date in ISO 8601 compliant format
    _getEndDate: ->
        end = @refs.dateEnd.getDOMNode().value.trim()
        if end is ''
            return ''
        else
            end = end.split '/'
            return "#{end[2]}-#{end[1]}-#{end[0]}T23:59:59.999Z"

    # Validate start and end dates
    # update state and return true if both are valid
    doValidate: ->
        start = @_getStartDate()
        end   = @_getEndDate()
        startValid = start is '' or not isNaN(Date.parse start)
        endValid   = end is '' or not isNaN(Date.parse end)
        @setState startValid: startValid, endValid: endValid
        return startValid and endValid

    # Update filter type
    onChange: (filter) ->
        @setState type: filter, startValid: true, endValid: true

    # Filter list
    onFilter: (ev) ->
        if ev?
            ev.stopPropagation()
            ev.preventDefault()

        if @state.type is 'date'
            if @doValidate()
                LayoutActionCreator.sortMessages
                    order: '-'
                    field:  @state.type
                    before: @_getStartDate()
                    after:  @_getEndDate()
        else
            value = @refs.value.getDOMNode().value
            LayoutActionCreator.sortMessages
                order:  '-'
                field:  @state.type
                after:  "#{value}\uFFFF"
                before: value

        params = _.clone(MessageStore.getParams())
        params.accountID = @props.accountID
        params.mailboxID = @props.mailboxID
        LayoutActionCreator.showMessageList parameters: params

    onKeyDown: (evt) ->
        switch evt.key
            when "Enter"
                @onFilter()

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
