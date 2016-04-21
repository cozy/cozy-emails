React      = require 'react'
{div, article, header, footer, i, p, a, textarea} = React.DOM
classNames = require 'classnames'

MessageHeader  = React.createFactory require './message_header'
MessageFooter  = React.createFactory require './message_footer'
ToolbarMessage = React.createFactory require './toolbar_message'
MessageContent = React.createFactory require './message-content'

{MessageFlags, MessageActions} = require '../constants/app_constants'

LayoutActionCreator = require '../actions/layout_action_creator'
RouterActionCreator = require '../actions/router_action_creator'


module.exports = React.createClass
    displayName: 'Message'


    componentWillUnMount: ->
        # Mark message as read
        messageID = @props.message?.get('id')
        console.log 'MARK_AS_READ', messageID
        # RouterActionCreator.mark {messageID}, MessageFlags.SEEN


    render: ->
        article
            className: classNames
                message: true
                active: @props.active
                isDraft: @props.isDraft
                isDeleted: @props.isDeleted
                isUnread: @props.isUnread
            key: "messageContainer-#{@props.message.get('id')}",

            if @props.active
                header null,
                    MessageHeader
                        ref: 'header'
                        key: "messageHeader-#{@props.message.get('id')}"
                        message: @props.message
                        isDraft: @props.isDraft
                        isDeleted: @props.isDeleted
                        active: @props.active,

            if @props.active
                MessageContent
                    ref: 'messageContent'
                    messageID: @props.message.get 'id'
                    html: @props.html
                    text: @props.text
                    rich: @props.rich
                    imagesWarning: @props.imagesWarning

            if @props.active
                footer null,
                    MessageFooter
                        ref: 'footer'
                        files: @props.message.get 'attachments'

            unless @props.active
                a
                    href: @props.messageURL
                    className: 'header',
                    MessageHeader
                        ref: 'header'
                        key: "messageHeader-#{@props.message.get('id')}"
                        message: @props.message
                        isDraft: @props.isDraft
                        isDeleted: @props.isDeleted
                        active: @props.active
