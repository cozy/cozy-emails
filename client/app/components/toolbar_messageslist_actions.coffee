React = require 'react'

{div, i, button} = React.DOM
{Tooltips}       = require '../constants/app_constants'

ToolboxActions = React.createFactory require './toolbox_actions'
ToolboxMove    = React.createFactory require './toolbox_move'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'
RouterActionCreator = require '../actions/router_action_creator'

MailboxesGetter = require '../getters/mailboxes'

module.exports = ActionsToolbarMessagesList = React.createClass
    displayName: 'ActionsToolbarMessagesList'

    propTypes:
        settings:             React.PropTypes.object.isRequired
        mailboxID:            React.PropTypes.string.isRequired
        messages:             React.PropTypes.object.isRequired
        selection:            React.PropTypes.array.isRequired


    _getSelectedAndMode: (applyToConversation) ->
        selected = @props.selection?.toArray()
        count = @props.selection.size
        applyToConversation = Boolean applyToConversation

        if selected.length is 0
            LayoutActionCreator.alertError t 'list mass no message'
            return false

        else
            conversationIDs = selected.map (id) =>
                isMessage = (message) -> message.get('id') is id
                if (message = @props.messages.find isMessage)
                    return message.get('conversationID')

            return {count, conversationIDs, applyToConversation}


    render: ->
        div role: 'group',
            button
                role:                     'menuitem'
                onClick:                  @onDelete
                'aria-disabled':          true
                'aria-describedby':       Tooltips.DELETE_SELECTION
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-trash-o'

            ToolboxActions
                direction:            'left'
                mode:                 'conversation'
                mailboxes:            MailboxesGetter.getSelected()
                onMark:               @onMark
                onConversationDelete: @onConversationDelete
                onConversationMark:   @onConversationMark
                onConversationMove:   @onConversationMove


    onDelete: (applyToConversation) ->
        return unless options = @_getSelectedAndMode applyToConversation

        doDelete = =>
            MessageActionCreator.delete options

            # Goto to next conversation
            RouterActionCreator.navigate action: 'conversation.next'

        unless @props.settings.get 'messageConfirmDelete'
            doDelete()
        else
            if options.applyToConversation
                msg = 'list delete conv confirm'
            else
                msg = 'list delete confirm'
            modal =
                title       : t 'app confirm delete'
                subtitle    : t msg, smart_count: options.count
                closeLabel  : t 'app cancel'
                actionLabel : t 'app confirm'
                action      : ->
                    doDelete()
                    LayoutActionCreator.hideModal()
            LayoutActionCreator.displayModal modal

    onMove: (to, applyToConversation) ->
        return unless options = @_getSelectedAndMode applyToConversation

        from = @props.mailboxID

        MessageActionCreator.move options, from, to, =>
            if options.count > 0 and @props.messages.size > 0
                firstMessageID = @props.messages.first().get('id')
                MessageActionCreator.setCurrent firstMessageID, true


    onMark: (flag, applyToConversation) ->
        return unless options = @_getSelectedAndMode applyToConversation
        MessageActionCreator.mark options, flag


    onConversationDelete: ->
        @onDelete true


    onConversationMove: (to) ->
        @onMove to, true


    onConversationMark: (flag) ->
        @onMark flag, true
