{nav, div, button, a} = React.DOM

{MessageFlags, FlagsConstants, Tooltips} = require '../constants/app_constants'

ToolboxActions = require './toolbox_actions'
ToolboxMove    = require './toolbox_move'

LayoutActionCreator       = require '../actions/layout_action_creator'
alertError                = LayoutActionCreator.alertError
alertSuccess              = LayoutActionCreator.notify

# Shortcuts for buttons classes
cBtnGroup = 'btn-group btn-group-sm pull-right'
cBtn      = 'btn btn-default fa'


module.exports = React.createClass
    displayName: 'ToolbarMessage'

    propTypes:
        message            : React.PropTypes.object.isRequired
        mailboxes          : React.PropTypes.object.isRequired
        selectedMailboxID  : React.PropTypes.string.isRequired
        onDelete           : React.PropTypes.func.isRequired
        onMove             : React.PropTypes.func.isRequired
        onHeaders          : React.PropTypes.func.isRequired


    render: ->
        nav
            className: 'toolbar toolbar-message btn-toolbar'
            onClick: (event) -> event.stopPropagation()
            # inverted order due to `pull-right` class
            div(className: cBtnGroup,
                @renderToolboxMove()
                @renderToolboxActions()) if @props.full
            @renderQuickActions() if @props.full
            @renderReply()


    renderReply: ->
        div className: cBtnGroup,
            a
                className: "#{cBtn} fa-mail-reply mail-reply"
                href: "#reply/#{@props.message.get 'id'}"
                'aria-describedby': Tooltips.REPLY
                'data-tooltip-direction': 'top'
            a
                className: "#{cBtn} fa-mail-reply-all mail-reply-all"
                href: "#reply-all/#{@props.message.get 'id'}"
                'aria-describedby': Tooltips.REPLY_ALL
                'data-tooltip-direction': 'top'
            a
                className: "#{cBtn} fa-mail-forward mail-forward"
                href: "#forward/#{@props.message.get 'id'}"
                'aria-describedby': Tooltips.FORWARD
                'data-tooltip-direction': 'top'


    renderQuickActions: ->
        div className: cBtnGroup,
            button
                className: "#{cBtn} fa-trash"
                onClick: @props.onDelete
                'aria-describedby': Tooltips.REMOVE_MESSAGE
                'data-tooltip-direction': 'top'


    renderToolboxActions: ->
        flags = @props.message.get('flags') or []
        isFlagged = FlagsConstants.FLAGGED in flags
        isSeen    = FlagsConstants.SEEN in flags

        ToolboxActions
            ref:            'toolboxActions'
            mailboxes:      @props.mailboxes
            inConversation: @props.inConversation
            isSeen:         isSeen
            isFlagged:      isFlagged
            messageID:      @props.message.get 'id'
            message:        @props.message
            onMark:         @props.onMark
            onHeaders:      @props.onHeaders
            onConversationMark: @props.onConversationMark
            onConversationMove: @props.onConversationMove
            onConversationDelete: @props.onConversationMove
            direction:      'right'
            displayConversations: false # to display messages actions


    renderToolboxMove: ->
        ToolboxMove
            ref:       'toolboxMove'
            mailboxes: @props.mailboxes
            onMove:    @props.onMove
            direction: 'right'

