{nav, div, button, a} = React.DOM

{MessageFlags, FlagsConstants, Tooltips} = require '../constants/app_constants'

ToolboxActions = require './toolbox_actions'
ToolboxMove    = require './toolbox_move'

LayoutActionCreator       = require '../actions/layout_action_creator'
ConversationActionCreator = require '../actions/conversation_action_creator'
MessageActionCreator      = require '../actions/message_action_creator'
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
        onReply            : React.PropTypes.func.isRequired
        onReplyAll         : React.PropTypes.func.isRequired
        onForward          : React.PropTypes.func.isRequired
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
            button
                className: "#{cBtn} fa-mail-reply mail-reply"
                onClick: @props.onReply
                'aria-describedby': Tooltips.REPLY
                'data-tooltip-direction': 'top'
            button
                className: "#{cBtn} fa-mail-reply-all mail-reply-all"
                onClick: @props.onReplyAll
                'aria-describedby': Tooltips.REPLY_ALL
                'data-tooltip-direction': 'top'
            button
                className: "#{cBtn} fa-mail-forward mail-forward"
                onClick: @props.onForward
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
            isSeen:         isSeen
            isFlagged:      isFlagged
            mailboxID:      @props.selectedMailboxID
            messageID:      @props.message.get 'id'
            message:        @props.message
            onMark:         @onMark
            onConversation: @onConversation
            onMove:         @props.onMove
            onHeaders:      @props.onHeaders
            direction:      'right'
            displayConversations: false # to display messages actions


    renderToolboxMove: ->
        ToolboxMove
            ref:       'toolboxMove'
            mailboxes: @props.mailboxes
            onMove:    @props.onMove
            direction: 'right'


    onMark: (args) ->
        flags = @props.message.get('flags').slice()
        flag = args.target.dataset.value
        switch flag
            when FlagsConstants.SEEN
                flags.push MessageFlags.SEEN
            when FlagsConstants.UNSEEN
                flags = flags.filter (e) -> return e isnt FlagsConstants.SEEN
            when FlagsConstants.FLAGGED
                flags.push MessageFlags.FLAGGED
            when FlagsConstants.NOFLAG
                flags = flags.filter (e) -> return e isnt FlagsConstants.FLAGGED
        MessageActionCreator.updateFlag @props.message, flags, (error) ->
            if error?
                alertError "#{t("message action mark ko")} #{error}"
            else
                alertSuccess t "message action mark ok"


    onConversation: (args) ->
        id     = @props.message.get 'conversationID'
        action = args.target.dataset.action
        switch action
            when 'delete'
                ConversationActionCreator.delete id, (error) ->
                    if error?
                        alertError "#{t("conversation delete ko")} #{error}"
                    else
                        alertSuccess t "conversation delete ok"
            when 'seen'
                ConversationActionCreator.seen id, (error) ->
                    if error?
                        alertError "#{t("conversation seen ko")} #{error}"
                    else
                        alertSuccess t "conversation seen ok"
            when 'unseen'
                ConversationActionCreator.unseen id, (error) ->
                    if error?
                        alertError "#{t("conversation unseen ko")} #{error}"
                    else
                        alertSuccess t "conversation unseen ok"
            when 'flagged'
                ConversationActionCreator.flag id, (error) ->
                    if error?
                        alertError "#{t("conversation flagged ko ")} #{error}"
            when 'noflag'
                ConversationActionCreator.noflag id, (error) ->
                    if error?
                        alertError "#{t("conversation noflag ko")} #{error}"
