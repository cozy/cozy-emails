{section, header, ul, li, span, i, p, h3, a, button} = React.DOM
Message = require './message'
Toolbar = require './toolbar_conversation'
classer = React.addons.classSet

RouterMixin = require '../mixins/router_mixin'
{MessageFlags} = require '../constants/app_constants'

module.exports = React.createClass
    displayName: 'Conversation'

    mixins: [RouterMixin]

    propTypes:
        message              : React.PropTypes.object
        conversation         : React.PropTypes.object
        selectedAccountID    : React.PropTypes.string.isRequired
        selectedAccountLogin : React.PropTypes.string.isRequired
        layout               : React.PropTypes.string.isRequired
        readability          : React.PropTypes.bool.isRequired
        selectedMailboxID    : React.PropTypes.string
        mailboxes            : React.PropTypes.object.isRequired
        settings             : React.PropTypes.object.isRequired
        accounts             : React.PropTypes.object.isRequired


    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))


    getInitialState: ->
        expanded: []


    renderToolbar: ->
        Toolbar
            readability         : @props.readability
            nextMessageID       : @props.nextMessageID
            nextConversationID  : @props.nextConversationID
            prevMessageID       : @props.prevMessageID
            prevConversationID  : @props.prevConversationID
            settings            : @props.settings


    renderMessage: (key, active) ->
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


    renderGroup: (messages, key) ->
        if messages.length > 3 and key not in @state.expanded
            items = []
            [first, ..., last] = messages
            items.push @renderMessage(first, false)
            items.push button
                className: 'more'
                onClick: =>
                    expanded = @state.expanded[..]
                    expanded.push key
                    @setState expanded: expanded
                t 'load more messages', messages.length - 2
                i className: 'fa fa-ellipsis-v'
            items.push @renderMessage(last, false)
        else
            items = (@renderMessage(key, false) for key in messages)

        return items


    render: ->
        if not @props.message? or not @props.conversation
            return p null, t "app loading"

        # Sort messages in conversation to find seen messages and group them
        messages = []
        lastMessageIndex = @props.conversation.length - 1
        @props.conversation.map((message, key) ->
            isSeen = MessageFlags.SEEN in message.get 'flags'

            if not isSeen or key is lastMessageIndex
                messages.push key
            else
                [..., last] = messages
                messages.push(last = []) unless _.isArray(last)
                last.push key
        ).toJS()

        # Starts components rendering
        section className: 'conversation',

            header null,
                @renderToolbar()
                h3
                    className: 'conversation-title'
                    'data-message-id': @props.message.get 'id'
                    @props.message.get 'subject'

            for glob, index in messages
                if _.isArray glob
                    @renderGroup glob, index
                else
                    @renderMessage glob, true
