React = require 'react'

{div, i, button} = React.DOM
{Tooltips}       = require '../constants/app_constants'

ToolboxActions = React.createFactory require './toolbox_actions'
ToolboxMove    = React.createFactory require './toolbox_move'

MessageStore = require '../stores/message_store'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'

RouterMixin = require '../mixins/router_mixin'


module.exports = ActionsToolbarMessagesList = React.createClass
    displayName: 'ActionsToolbarMessagesList'

    mixins: [
        RouterMixin
    ]

    propTypes:
        settings:             React.PropTypes.object.isRequired
        mailboxID:            React.PropTypes.string.isRequired
        mailboxes:            React.PropTypes.object.isRequired
        messages:             React.PropTypes.object.isRequired
        selected:             React.PropTypes.object.isRequired
        afterAction:          React.PropTypes.func


    _hasSelection: ->
        Object.keys(@props.selected).length > 0


    _getSelectedAndMode: (applyToConversation) ->
        selected = Object.keys @props.selected
        count = selected.length
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
                'aria-disabled':          @_hasSelection()
                'aria-describedby':       Tooltips.DELETE_SELECTION
                'data-tooltip-direction': 'bottom'

                i className: 'fa fa-trash-o'

            ToolboxActions
                direction:            'left'
                mode: 'conversation'
                mailboxes:            @props.mailboxes
                onMark:               @onMark
                onConversationDelete: @onConversationDelete
                onConversationMark:   @onConversationMark
                onConversationMove:   @onConversationMove


    onDelete: (applyToConversation) ->
        return unless options = @_getSelectedAndMode applyToConversation

        doDelete = =>
            # Get next focus conversation
            conversationIDs = options.conversationIDs
            nextConversation = MessageStore.getPreviousConversation {conversationIDs}
            nextConversation = MessageStore.getNextConversation {conversationIDs} unless nextConversation.size

            MessageActionCreator.delete options

            @props.afterAction() if @props.afterAction?

            unless nextConversation.size
                # Close 2nd panel : no next conversation found
                @redirect @buildClosePanelUrl 'second'
            else
                # Goto to next conversation
                @redirect
                    direction: 'second',
                    action: 'conversation',
                    parameters:
                        messageID: nextConversation.get('id')
                        conversationID: nextConversation.get('conversationID')

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
        if @props.afterAction?
            @props.afterAction()


    onMark: (flag, applyToConversation) ->
        return unless options = @_getSelectedAndMode applyToConversation
        MessageActionCreator.mark options, flag


    onConversationDelete: ->
        @onDelete true


    onConversationMove: (to) ->
        @onMove to, true


    onConversationMark: (flag) ->
        @onMark flag, true
