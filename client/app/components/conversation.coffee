{div, ul, li, span, i, p, h3, a} = React.DOM
Message = require './message'
classer = React.addons.classSet

LayoutActionCreator = require '../actions/layout_action_creator'

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
        selectedMailboxID    : React.PropTypes.string
        mailboxes            : React.PropTypes.object.isRequired
        settings             : React.PropTypes.object.isRequired
        accounts             : React.PropTypes.object.isRequired

    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))

    getInitialState: ->
        expanded: not @props.settings.get('displayConversation')

    expand: ->
        @setState expanded: true

    renderMessage: (key, message, active) ->
        Message
            ref                 : 'message'
            accounts            : @props.accounts
            active              : active
            inConversation      : @props.conversation.length > 1
            key                 : key
            mailboxes           : @props.mailboxes
            message             : message
            nextMessageID       : @props.nextMessageID
            nextConversationID  : @props.nextConversationID
            prevMessageID       : @props.prevMessageID
            prevConversationID  : @props.prevConversationID
            selectedAccountID   : @props.selectedAccountID
            selectedAccountLogin: @props.selectedAccountLogin
            selectedMailboxID   : @props.selectedMailboxID
            settings            : @props.settings

    render: ->
        if not @props.message? or not @props.conversation
            return p null, t "app loading"

        expandUrl = @buildUrl
            direction: 'first'
            action: 'message'
            parameters: @props.message.get 'id'
            fullWidth: true

        if window.router.previous?
            try
                selectedAccountID = @props.selectedAccountID
            catch
                selectedAccountID = @props.conversation.get(0).mailbox
        else
            selectedAccountID = @props.conversation.get(0).mailbox

        if @props.layout is 'full'
            closeUrl = @buildUrl
                direction: 'first'
                action: 'account.mailbox.messages'
                parameters: selectedAccountID
                fullWidth: true
        else
            closeUrl = @buildClosePanelUrl @props.layout

        closeIcon = if @props.layout is 'full' then 'fa-th-list' else 'fa-times'

        otherMessages = {}
        activeMessages = {}

        @props.conversation.map (message, key) =>
            # open every unseen message of the conversation
            if @props.message.get('id') is message.get('id') or
                    MessageFlags.SEEN not in message.get('flags')

                activeMessages[key] = message

            else
                otherMessages[key] = message

        .toJS()

        toggleFullscreen = ->
            LayoutActionCreator.toggleFullscreen()

        div className: 'conversation',

            if @props.layout isnt 'full'
                a
                    onClick: toggleFullscreen
                    className: 'expand hidden-xs hidden-sm clickable',
                        i className: 'fa fa-arrows-h'
            else
                a
                    onClick: toggleFullscreen
                    className: 'compress clickable',
                        i className:'fa fa-compress'

            h3
                className: 'message-title'
                'data-message-id': @props.message.get 'id'
                @props.message.get 'subject'

            ul className: 'thread list-unstyled',

                if @state.expanded
                    for key, message of otherMessages
                        @renderMessage key, message, false

                else if @props.conversationLength > 1
                    li className: 'conversation-length-msg', onClick: @expand,
                        a null
                            t 'mail conversation length',
                                smart_count: @props.conversationLength

                for key, message of activeMessages
                    @renderMessage key, message, true
