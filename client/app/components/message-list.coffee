{div, section, p, ul, li, a, span, i, button, input, img} = React.DOM
{MessageFlags, Tooltips} = require '../constants/app_constants'

RouterMixin           = require '../mixins/router_mixin'
TooltipRefresherMixin = require '../mixins/tooltip_refresher_mixin'

classer      = React.addons.classSet
DomUtils     = require '../utils/dom_utils'
MessageUtils = require '../utils/message_utils'
SocketUtils  = require '../utils/socketio_utils'
colorhash    = require '../utils/colorhash'

ContactActionCreator = require '../actions/contact_action_creator'
LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

Participants        = require './participant'
{Spinner}           = require './basic_components'
ToolbarMessagesList = require './toolbar_messageslist'


module.exports = MessageList = React.createClass
    displayName: 'MessageList'

    mixins: [RouterMixin, TooltipRefresherMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        should = not(_.isEqual(nextState, @state)) or
            not (_.isEqual(nextProps, @props))
        return should

    getInitialState: ->
        edited: false
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

        section
            key:               'messages-list'
            ref:               'list'
            'data-mailbox-id': @props.mailboxID
            className:         'messages-list panel'
            'aria-expanded':   true

            # Drawer toggler
            button
                className: 'drawer-toggle'
                onClick:   LayoutActionCreator.drawerToggle
                title:     t 'menu toggle'

                i className: 'fa fa-navicon'

            # Toolbar
            ToolbarMessagesList
                accountID:            @props.accountID
                mailboxID:            @props.mailboxID
                mailboxes:            @props.mailboxes
                messages:             @props.messages
                edited:               @state.edited
                selected:             @state.selected
                displayConversations: @props.displayConversations
                toggleEdited:         @toggleEdited
                toggleAll:            @toggleAll

            # Message List
            if @props.messages.count() is 0
                if @props.fetching
                    p null, t 'list fetching'
                else
                    p null, @props.emptyListMessage
            else
                div className: 'main-content',
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
        ul className: 'list-unstyled',
            @props.messages.map((message, key) =>
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
            ).toJS()

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
            unseen:  MessageFlags.SEEN not in flags
            active:  @props.isActive
            edited:  @props.edited

        if MessageFlags.DRAFT in flags and not @props.isTrash
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

        compact = @props.settings.get('listStyle') is 'compact'
        date    = MessageUtils.formatDate message.get('createdAt'), compact
        avatar  = MessageUtils.getAvatar message
        text    = message.get('text')

        li
            className:              classes
            key:                    @props.key
            'data-message-id':      message.get('id')
            'data-conversation-id': message.get('conversationID')
            draggable:              not @props.edited
            onClick:                @onMessageClick
            onDragStart:            @onDragStart,

            # Change tag type if current message is in edited mode
            (if @props.edited then span else a)
                href:              url
                className:         'wrapper'
                'data-message-id': message.get('id')
                onClick:           @onMessageClick
                onDoubleClick:     @onMessageDblClick
                ref:               'target'

                div className: 'markers-wrapper',
                    if MessageFlags.SEEN in flags
                        i className: 'fa fa-circle-thin'
                    else
                        i className: 'fa fa-circle'
                    if MessageFlags.FLAGGED in flags
                        i className: 'fa fa-star'

                div className: 'avatar-wrapper select-target',
                    input
                        ref:       'select'
                        className: 'select select-target',
                        type:      'checkbox',
                        checked:   @props.selected,
                        onChange:  @onSelect

                    if avatar?
                        img className: 'avatar', src: avatar
                    else
                        from  = message.get('from')[0]
                        cHash = "#{from.name} <#{from.address}>"
                        i
                            className: 'avatar placeholder'
                            style:
                                'background-color': colorhash(cHash)
                            from.name[0]

                div className: 'metas-wrapper',
                    div className: 'participants',
                        @getParticipants message
                    div className: 'subject',
                        message.get 'subject'
                    div className: 'date',
                        # TODO: use time-elements component here for the date
                        date
                    div className: 'extras',
                        if message.get 'hasAttachments'
                            i className: 'attachments fa fa-paperclip'
                        if  @props.displayConversations and
                            @props.conversationLengths > 1
                                i className: 'conversation-length fa fa-chevron-right',
                                    @props.conversationLengths
                    div className: 'preview',
                        text.substr(0, 1024)

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
