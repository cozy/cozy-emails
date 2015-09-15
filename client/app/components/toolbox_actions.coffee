{div, ul, li, span, a, button} = React.DOM
{MenuHeader, MenuItem, MenuDivider} = require './basic_components'
{FlagsConstants} = require '../constants/app_constants'


module.exports = ToolboxActions = React.createClass
    displayName: 'ToolboxActions'


    propTypes:

        direction            : React.PropTypes.string.isRequired
        displayConversations : React.PropTypes.bool.isRequired
        isFlagged            : React.PropTypes.bool
        isSeen               : React.PropTypes.bool
        mailboxes            : React.PropTypes.object.isRequired
        message              : React.PropTypes.object
        messageID            : React.PropTypes.string
        onConversationDelete : React.PropTypes.func.isRequired
        onConversationMark   : React.PropTypes.func.isRequired
        onConversationMove   : React.PropTypes.func.isRequired
        onHeaders            : React.PropTypes.func
        onMark               : React.PropTypes.func.isRequired


    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))


    render: ->
        direction = if @props.direction is 'right' then 'right' else 'left'
        div className: 'menu-action btn-group btn-group-sm',
            button
                className: 'btn btn-default dropdown-toggle fa fa-cog'
                type: 'button'
                'data-toggle': 'dropdown'
                ' '
                    span className: 'caret'
            ul
                className: "dropdown-menu dropdown-menu-#{direction}"
                role: 'menu',
                    # in conversation mode, only shows actions on conversation
                    if not @props.displayConversations
                        @renderMarkActions()
                    if not @props.displayConversations
                        MenuDivider()
                    @renderRawActions()...
                    if @props.inConversation
                        @renderConversationActions()
                    if @props.inConversation
                        MenuDivider key: 'divider'
                    if @props.inConversation
                        MenuHeader key: 'header-move',
                            t 'mail action conversation move'
                    if @props.inConversation
                        @renderMailboxes()


    renderMarkActions: ->
        items = [
            MenuHeader key: 'header-mark', t 'mail action mark'

            if not @props.isSeen? or not @props.isSeen
                MenuItem
                    key: 'action-mark-seen'
                    onClick: => @props.onMark FlagsConstants.SEEN
                    t 'mail mark read'
            if not @props.isSeen? or @props.isSeen
                MenuItem
                    key: 'action-mark-unseen'
                    onClick: => @props.onMark FlagsConstants.UNSEEN
                    t 'mail mark unread'

            if not @props.isFlagged? or @props.isFlagged
                MenuItem
                    key: 'action-mark-noflag'
                    onClick: => @props.onMark FlagsConstants.NOFLAG
                    t 'mail mark nofav'
            if not @props.isFlagged? or not @props.isFlagged
                MenuItem
                    key: 'action-mark-flagged'
                    onClick: => @props.onMark FlagsConstants.FLAGGED
                    t 'mail mark fav'

        ]

        # remove undefined values from the array
        return items.filter (child) -> Boolean child


    renderRawActions: ->
        items = [

            if not @props.displayConversations
                MenuHeader key: 'header-more', t 'mail action more'

            if @props.messageID?
                MenuItem
                    key: 'action-headers'
                    onClick: @props.onHeaders,
                    t 'mail action headers'

            if @props.message?
                MenuItem
                    key: 'action-raw'
                    href:   "raw/#{@props.message.get 'id'}"
                    target: '_blank'
                    t 'mail action raw'
        ]

        # remove undefined values from the array
        return items.filter (child) -> Boolean child


    renderConversationActions: ->
        items = [
            MenuItem
                key: 'conv-delete'
                onClick: @props.onConversationDelete,
                t 'mail action conversation delete'

            MenuItem
                key: 'conv-seen'
                onClick: => @props.onConversationMark FlagsConstants.SEEN
                t 'mail action conversation seen'

            MenuItem
                key: 'conv-unseen'
                onClick: => @props.onConversationMark FlagsConstants.UNSEEN
                t 'mail action conversation unseen'

            MenuItem
                key: 'conv-flagged'
                onClick: => @props.onConversationMark FlagsConstants.FLAGGED
                t 'mail action conversation flagged'

            MenuItem
                key: 'conv-noflag'
                onClick: => @props.onConversationMark FlagsConstants.NOFLAG
                t 'mail action conversation noflag'
        ]

        return items


    renderMailboxes: ->
        for id, mbox of @props.mailboxes when id isnt @props.selectedMailboxID
            # bind id
            do (id) =>
                MenuItem
                    key: id
                    className: "pusher pusher-#{mbox.depth}"
                    onClick: => @props.onConversationMove id
                    mbox.label

