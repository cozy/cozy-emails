{section, header, ul, li, span, i, p, h3, a, button} = React.DOM
Message = require './message'
Toolbar = require './toolbar_conversation'
classer = React.addons.classSet

RouterMixin = require '../mixins/router_mixin'
{MessageFlags} = require '../constants/app_constants'

LayoutActionCreator = require '../actions/layout_action_creator'


module.exports = React.createClass
    displayName: 'Conversation'

    mixins: [RouterMixin]

    propTypes:
        conversation         : React.PropTypes.object
        conversationID       : React.PropTypes.string
        selectedAccountID    : React.PropTypes.string.isRequired
        selectedAccountLogin : React.PropTypes.string.isRequired
        selectedMailboxID    : React.PropTypes.string
        mailboxes            : React.PropTypes.object.isRequired
        settings             : React.PropTypes.object.isRequired
        accounts             : React.PropTypes.object.isRequired
        displayConversations : React.PropTypes.bool
        useIntents           : React.PropTypes.bool.isRequired


    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))


    # Init an array with keys of expanded articles
    _initExpanded: (props) ->
        props ?= @props
        expanded = []
        if props.conversation?
            # set first expanded message: first unseen or last of conversation
            props.conversation.map((message, key) ->
                isUnread = MessageFlags.SEEN not in message.get 'flags'
                isLast   = key is props.conversation.length - 1
                if (expanded.length is 0 and (isUnread or isLast))
                    expanded.push key
            ).toJS()
        return expanded

    getInitialState: ->
        # compact: set to true to not display all messages in conversation
        return {
            expanded: @_initExpanded()
            compact: true
        }

    componentWillReceiveProps: (props) ->
        if props.conversation?.length isnt @props.conversation?.length
            expanded = @_initExpanded(props)
            @setState expanded: expanded, compact: true

    renderToolbar: ->
        Toolbar
            readability         : @props.readability
            nextMessageID       : @props.nextMessageID
            nextConversationID  : @props.nextConversationID
            prevMessageID       : @props.prevMessageID
            prevConversationID  : @props.prevConversationID
            settings            : @props.settings


    renderMessage: (key, active) ->
        # allow the Message component to update current active message
        # in conversation. Needed to open the first unread message when
        # opening a conversation
        toggleActive = =>
            expanded = @state.expanded[..]
            if key in expanded
                expanded = expanded.filter (id) -> return key isnt id
            else
                expanded.push key
            @setState expanded: expanded

        Message
            ref                 : 'message'
            accounts            : @props.accounts
            active              : active
            inConversation      : @props.conversation.length > 1
            key                 : key.toString()
            mailboxes           : @props.mailboxes
            message             : @props.conversation.get key
            selectedAccountID   : @props.selectedAccountID
            selectedAccountLogin: @props.selectedAccountLogin
            selectedMailboxID   : @props.selectedMailboxID
            settings            : @props.settings
            displayConversations: @props.displayConversation
            useIntents          : @props.useIntents
            toggleActive        : toggleActive


    renderGroup: (messages, key) ->
        # if there are more than 3 messages, by default only render
        # first and last ones
        if messages.length > 3 and @state.compact
            items = []
            [first, ..., last] = messages
            items.push @renderMessage(first, false)
            items.push button
                className: 'more'
                onClick: =>
                    @setState compact: false
                i className: 'fa fa-refresh'
                t 'load more messages', messages.length - 2
            items.push @renderMessage(last, false)
        else
            items = (@renderMessage(key, false) for key in messages)

        return items


    render: ->
        if not @props.conversation
            return section
                key: 'conversation'
                className: 'conversation panel'
                'aria-expanded': true,
                p null, t "app loading"

        message = @props.conversation.get 0
        # Sort messages in conversation to find seen messages and group them
        messages = []
        lastMessageIndex = @props.conversation.length - 1
        @props.conversation.map((message, key) =>
            if key in @state.expanded
                messages.push key
            else
                [..., last] = messages
                messages.push(last = []) unless _.isArray(last)
                last.push key
        ).toJS()

        # Starts components rendering
        section
            key: 'conversation'
            className: 'conversation panel'
            'aria-expanded': true,

            header null,
                h3
                    className: 'conversation-title'
                    'data-message-id': message.get 'id'
                    'data-conversation-id': message.get 'conversationID'
                    message.get 'subject'
                @renderToolbar()
                a
                    className: 'clickable btn btn-default fa fa-close'
                    href: @buildClosePanelUrl 'second'
                    onClick: LayoutActionCreator.minimizePreview

            for glob, index in messages
                if _.isArray glob
                    @renderGroup glob, index
                else
                    @renderMessage glob, true
