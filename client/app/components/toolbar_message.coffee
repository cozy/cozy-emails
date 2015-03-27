{nav, div, button, a} = React.DOM

{FlagsConstants} = require '../constants/app_constants'

ToolboxActions = require './toolbox_actions'
ToolboxMove    = require './toolbox_move'

# Shortcuts for buttons classes
cBtnGroup = 'btn-group btn-group-sm pull-right'
cBtn      = 'btn btn-default fa'


module.exports = React.createClass
    displayName: 'ToolbarMessage'

    propTypes:
        message            : React.PropTypes.object.isRequired
        flags              : React.PropTypes.array
        mailboxes          : React.PropTypes.object.isRequired
        selectedMailboxID  : React.PropTypes.string.isRequired
        onReply            : React.PropTypes.func.isRequired
        onReplyAll         : React.PropTypes.func.isRequired
        onForward          : React.PropTypes.func.isRequired
        onDelete           : React.PropTypes.func.isRequired
        onMark             : React.PropTypes.func.isRequired
        onMove             : React.PropTypes.func.isRequired
        onConversation     : React.PropTypes.func.isRequired
        onHeaders          : React.PropTypes.func.isRequired


    render: ->
        nav className: 'toolbar toolbar-message btn-toolbar',
            # inverted order due to `pull-right` class
            div className: cBtnGroup,
                @renderToolboxMove()
                @renderToolboxActions()
            @renderQuickActions()
            @renderReply()


    renderReply: ->
        div className: cBtnGroup,
            button
                className: "#{cBtn} fa-mail-reply"
                onClick: @props.onReply
            button
                className: "#{cBtn} fa-mail-reply-all"
                onClick: @props.onReplayAll
            button
                className: "#{cBtn} fa-mail-forward"
                onClick: @props.onForward


    renderQuickActions: ->
        div className: cBtnGroup,
            button
                className: "#{cBtn} fa-trash"
                onClick: @props.onDelete


    renderToolboxActions: ->
        isFlagged = FlagsConstants.FLAGGED in @props.flags
        isSeen    = FlagsConstants.SEEN in @props.flags

        ToolboxActions
            ref:            'toolboxActions'
            mailboxes:      @props.mailboxes
            isSeen:         !isSeen
            isFlagged:      !isFlagged
            mailboxID:      @props.selectedMailboxID
            messageID:      @props.message.get 'id'
            message:        @props.message
            onMark:         @onMark
            onMove:         @onMove
            onConversation: @onConversation
            onHeaders:      @onHeaders
            direction:      'right'


    renderToolboxMove: ->
        ToolboxMove
            ref:       'toolboxMove'
            mailboxes: @props.mailboxes
            onMove:    @onMove
            direction: 'right'
