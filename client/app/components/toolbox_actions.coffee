_     = require 'underscore'
React = require 'react'

{div, ul, li, span, a, button} = React.DOM

{   Menu
    MenuHeader
    MenuItem
    MenuDivider} = require('./basic_components').factories
{FlagsConstants} = require '../constants/app_constants'


# This component is used in 3 places
#  - for the conversation
#  - for the message
#  - at the top of the list on selection

module.exports = ToolboxActions = React.createClass
    displayName: 'ToolboxActions'

    propTypes:
        # let the dropdown be aligned on right or left
        direction            : React.PropTypes.string.isRequired
        # one of conversation / message
        mode                 : React.PropTypes.string.isRequired
        # is the message or all messages flagged
        isFlagged            : React.PropTypes.bool
        # is the message or all messages seen
        isSeen               : React.PropTypes.bool
        # mailboxes this message can be moved to
        mailboxes            : React.PropTypes.object.isRequired
        # id of the message we are working on (empty for conversation)
        messageID            : React.PropTypes.string
        # handlers for action
        onConversationDelete : React.PropTypes.func.isRequired
        onConversationMark   : React.PropTypes.func.isRequired
        onConversationMove   : React.PropTypes.func.isRequired
        onHeaders            : React.PropTypes.func
        onMark               : React.PropTypes.func


    shouldComponentUpdate: (nextProps, nextState) ->
        return not(_.isEqual(nextState, @state)) or
               not(_.isEqual(nextProps, @props))

    render: ->
        message = @props.mode is 'message'
        conversation = @props.mode is 'conversation'
        Menu
            icon: 'fa-cog'
            direction: if @props.direction is 'right' then 'right' else 'left'
        ,

            if message
                MenuHeader key: 'header-mark', t 'mail action mark'

            if message and @props.isSeen isnt true
                MenuItem
                    key: 'action-mark-seen'
                    onClick: @props.onMark
                    onClickValue: FlagsConstants.SEEN
                    t 'mail mark read'

            if message and @props.isSeen isnt false
                MenuItem
                    key: 'action-mark-unseen'
                    onClick: @props.onMark
                    onClickValue: FlagsConstants.UNSEEN
                    t 'mail mark unread'

            if message and @props.isFlagged isnt false
                MenuItem
                    key: 'action-mark-noflag'
                    onClick: @props.onMark
                    onClickValue: FlagsConstants.NOFLAG
                    t 'mail mark nofav'

            if message and @props.isFlagged isnt true
                MenuItem
                    key: 'action-mark-flagged'
                    onClick: @props.onMark
                    onClickValue: FlagsConstants.FLAGGED
                    t 'mail mark fav'

            if message
                MenuHeader key: 'header-more', t 'mail action more'

            if message
                MenuItem
                    key: 'action-headers'
                    onClick: @props.onHeaders,
                    t 'mail action headers'

            if message
                MenuItem
                    key: 'action-raw'
                    href:   "raw/#{@props.messageID}"
                    target: '_blank'
                    t 'mail action raw'

            if conversation
                MenuHeader key: 'header-conv', t 'mail action conversation'

            if conversation
                MenuItem
                    key: 'conv-delete'
                    onClick: @props.onConversationDelete,
                    t 'mail action conversation delete'

            if conversation and @props.isSeen isnt true
                MenuItem
                    key: 'conv-seen'
                    onClick: @props.onConversationMark
                    onClickValue: FlagsConstants.SEEN
                    t 'mail action conversation seen'

            if conversation and @props.isSeen isnt false
                MenuItem
                    key: 'conv-unseen'
                    onClick: @props.onConversationMark
                    onClickValue: FlagsConstants.UNSEEN
                    t 'mail action conversation unseen'

            if conversation and @props.isFlagged isnt true
                MenuItem
                    key: 'conv-flagged'
                    onClick: @props.onConversationMark
                    onClickValue: FlagsConstants.FLAGGED
                    t 'mail action conversation flagged'

            if conversation and @props.isFlagged isnt false
                MenuItem
                    key: 'conv-noflag'
                    onClick: @props.onConversationMark
                    onClickValue: FlagsConstants.NOFLAG
                    t 'mail action conversation noflag'

            if conversation
                MenuHeader key: 'header-move', t 'mail action conversation move'

            if conversation
                @props.mailboxes.map (mbox, id) =>
                    MenuItem
                        key: id
                        className: "pusher pusher-#{mbox.get('depth')}"
                        onClick: @props.onConversationMove
                        onClickValue: id
                        mbox.get('label')
                .toArray()
