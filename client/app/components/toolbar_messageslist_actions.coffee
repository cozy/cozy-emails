{div, i, button} = React.DOM
{Tooltips}       = require '../constants/app_constants'

ToolboxActions = require './toolbox_actions'
ToolboxMove    = require './toolbox_move'

LayoutActionCreator  = require '../actions/layout_action_creator'
MessageActionCreator = require '../actions/message_action_creator'


module.exports = ActionsToolbarMessagesList = React.createClass
    displayName: 'ActionsToolbarMessagesList'

    propTypes:
        settings:             React.PropTypes.object.isRequired
        mailboxID:            React.PropTypes.string.isRequired
        mailboxes:            React.PropTypes.object.isRequired
        messages:             React.PropTypes.object.isRequired
        selected:             React.PropTypes.object.isRequired
        displayConversations: React.PropTypes.bool.isRequired
        afterAction:          React.PropTypes.func


    _hasSelection: ->
        Object.keys(@props.selected).length > 0


    _getSelectedAndMode: (applyToConversation) ->
        selected = Object.keys @props.selected
        count = selected.length
        applyToConversation = Boolean applyToConversation
        applyToConversation ?= @props.displayConversations
        if selected.length is 0
            LayoutActionCreator.alertError t 'list mass no message'
            return false

        else if not applyToConversation
            return {count, messageIDs: selected, applyToConversation}

        else
            conversationIDs = selected.map (id) =>
                @props.messages.get(id).get('conversationID')

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

            unless @props.displayConversations
                ToolboxMove
                    ref:       'listToolboxMove'
                    mailboxes: @props.mailboxes
                    onMove:    @onMove
                    direction: 'left'

            ToolboxActions
                ref:                  'listToolboxActions'
                direction:            'left'
                mailboxes:            @props.mailboxes
                inConversation      : true
                displayConversations: @props.displayConversations
                onMark:               @onMark
                onConversationDelete: @onConversationDelete
                onConversationMark:   @onConversationMark
                onConversationMove:   @onConversationMove


    onDelete: (applyToConversation) ->
        return unless options = @_getSelectedAndMode(applyToConversation)

        if options.applyToConversation
            msg = t 'list delete conv confirm', smart_count: options.count
        else
            msg = t 'list delete confirm', smart_count: options.count

        doDelete = =>
            MessageActionCreator.delete options, =>
                if options.count > 0 and @props.messages.count() > 0
                    firstMessageID = @props.messages.first().get('id')
                    MessageActionCreator.setCurrent firstMessageID, true
            if @props.afterAction?
                @props.afterAction()

        noConfirm = not @props.settings.get('messageConfirmDelete')
        if noConfirm
            doDelete()
        else
            modal =
                title       : t 'app confirm delete'
                subtitle    : msg
                closeModal  : ->
                    LayoutActionCreator.hideModal()
                closeLabel  : t 'app cancel'
                actionLabel : t 'app confirm'
                action      : ->
                    doDelete()
                    LayoutActionCreator.hideModal()
            LayoutActionCreator.displayModal modal


    onMove: (to, applyToConversation) ->
        return unless options = @_getSelectedAndMode(applyToConversation)

        from = @props.mailboxID

        MessageActionCreator.move options, from, to, =>
            if options.count > 0 and @props.messages.count() > 0
                firstMessageID = @props.messages.first().get('id')
                MessageActionCreator.setCurrent firstMessageID, true
        if @props.afterAction?
            @props.afterAction()


    onMark: (flag, applyToConversation) ->
        return unless options = @_getSelectedAndMode(applyToConversation)
        MessageActionCreator.mark options, flag


    onConversationDelete: ->
        @onDelete true


    onConversationMove: (to) ->
        @onMove to, true


    onConversationMark: (flag) ->
        @onMark flag, true
