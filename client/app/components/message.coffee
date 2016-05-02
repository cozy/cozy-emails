React      = require 'react'
{div, article, footer, ul, i, p, a, textarea} = React.DOM
classNames = require 'classnames'

MessageHeader  = React.createFactory require './message_header'
ToolbarMessage = React.createFactory require './toolbar_message'
MessageContent = React.createFactory require './message-content'
AttachmentPreview = React.createFactory require './attachement_preview'

RouterGetter = require '../getters/router'
ContactGetter = require '../getters/contact'
IconGetter = require '../getters/icon'

RouterActionCreator = require '../actions/router_action_creator'
{MessageFlags} = require '../constants/app_constants'

module.exports = React.createClass
    displayName: 'Message'

    componentWillUnmount: ->
        # Mark message as read
        if @props?.message?.size and @props.active
            messageID = @props.message.get 'id'
            RouterActionCreator.mark {messageID}, MessageFlags.SEEN


    renderAttachement: (file, index, isPreview=false) ->
        file = file?.toJS()
        AttachmentPreview
            ref: "attachmentPreview-#{index}"
            key: "messageAttachement-#{file.checksum}"
            file: file
            fileSize: RouterGetter.getFileSize file
            icon: IconGetter.getAttachmentIcon file
            isPreview: isPreview


    render: ->
        {message} = @props

        messageID = message.get 'id'

        article
            ref: "messageContainer-#{messageID}"
            key: "messageContainer-#{messageID}"
            className: classNames
                message: true
                active: @props.active
                isDraft: @props.isDraft
                isDeleted: @props.isDeleted
                isUnread: @props.isUnread,

            MessageHeader
                ref: "messageHeader-#{messageID}"
                key: "messageHeader-#{messageID}"
                message: message
                contacts: ContactGetter.getAll message
                avatar: ContactGetter.getAvatar message
                createdAt: RouterGetter.getCreatedAt message
                isDraft: @props.isDraft
                isDeleted: @props.isDeleted
                isFlagged: @props.isFlagged
                active: @props.active,


            if @props.active
                ToolbarMessage
                    ref         : "toolbarMessage-#{messageID}"
                    key         : "toolbarMessage-#{messageID}"
                    isFull      : true
                    messageID   : messageID

            if @props.active
                MessageContent
                    ref: "messageContent-#{messageID}"
                    key: "messageContent-#{messageID}"
                    messageID: messageID
                    html: @props.html
                    text: @props.text
                    rich: @props.rich
                    imagesWarning: @props.imagesWarning

            if @props.active
                footer
                    ref: "messageFooter-#{messageID}"
                    key: "messageFooter-#{messageID}"
                    className: 'attachments',
                    ul null,
                        @props.resources.get('preview')?.map (file, index) =>
                            @renderAttachement file, index, true
                        @props.resources.get('binary')?.map (file, index) =>
                            @renderAttachement file, index, false
