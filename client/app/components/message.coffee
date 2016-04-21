React      = require 'react'
{div, article, footer, i, p, a, textarea} = React.DOM
classNames = require 'classnames'

MessageHeader  = React.createFactory require './message_header'
MessageFooter  = React.createFactory require './message_footer'
ToolbarMessage = React.createFactory require './toolbar_message'
MessageContent = React.createFactory require './message-content'

{MessageFlags, MessageActions} = require '../constants/app_constants'

LayoutActionCreator = require '../actions/layout_action_creator'
RouterActionCreator = require '../actions/router_action_creator'

messageUtils = require '../utils/message_utils'

module.exports = React.createClass
    displayName: 'Message'

    componentWillUnMount: ->
        # Mark message as read
        messageID = @props.message?.get('id')
        console.log 'MARK_AS_READ', messageID
        # RouterActionCreator.mark {messageID}, MessageFlags.SEEN

    gotoMessage: ->
        messageID = @props.message?.get('id')
        RouterActionCreator.navigate {messageID}


    render: ->
        createdAt = @props.message.get 'createdAt'
        article
            className: classNames
                message: true
                active: @props.active
                isDraft: @props.isDraft
                isDeleted: @props.isDeleted
                isUnread: @props.isUnread
            key: "messageContainer-#{@props.message.get('id')}",

            # FIXME : le click ne fonctionne pas
            # conflit avec 'MessageHeader'?!
            MessageHeader
                ref: 'header'
                key: "messageHeader-#{@props.message.get('id')}"
                message: @props.message
                avatar: messageUtils.getAvatar @props.message
                createdAt: messageUtils.formatDate createdAt
                isDraft: @props.isDraft
                isDeleted: @props.isDeleted
                isFlagged: MessageFlags.FLAGGED in @props.message.get('flags')
                active: @props.active,

            # FIXME : il existe une erreur dans le composant
            # if @props.active
            #     ToolbarMessage
            #         ref         : 'messageToolbar'
            #         isFull      : true
            #         messageID   : @props.message.get('id')


            # if @props.active
            #     MessageContent
            #         ref: 'messageContent'
            #         messageID: @props.message.get 'id'
            #         html: @props.html
            #         text: @props.text
            #         rich: @props.rich
            #         imagesWarning: @props.imagesWarning
            #
            # if @props.active
            #         MessageFooter
            #             ref: 'footer'
            #             files: @props.message.get 'attachments'
