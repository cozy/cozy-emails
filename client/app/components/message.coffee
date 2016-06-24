React = require 'react'
{article, footer, ul, i, p, a} = React.DOM
classNames = require 'classnames'

MessageHeader  = React.createFactory require './message_header'
ToolbarMessage = React.createFactory require './toolbar_message'
MessageContent = React.createFactory require './message-content'
AttachmentPreview = React.createFactory require './attachement_preview'

MessageGetter = require '../getters/message'
ContactGetter = require '../getters/contact'
FileGetter = require '../getters/file'

RouterActionCreator = require '../actions/router_action_creator'

{MessageFlags} = require '../constants/app_constants'


module.exports = React.createClass
    displayName: 'Message'


    renderAttachement: (file, index, isPreview=false) ->
        file = file?.toJS()
        AttachmentPreview
            ref: "attachmentPreview-#{index}"
            key: "messageAttachement-#{file.checksum}"
            file: file
            fileSize: FileGetter.getFileSize file
            icon: FileGetter.getAttachmentIcon file
            isPreview: isPreview


    render: ->
        article
            ref: "message-#{@props.messageID}-container"
            key: "message-#{@props.messageID}-container"
            'data-message-active': @props.isActive,
            className: classNames
                message: true
                active: @props.isActive
                isDraft: @props.isDraft
                isDeleted: @props.isDeleted
                isUnread: @props.isUnread,

            MessageHeader
                ref: "message-#{@props.messageID}-header"
                key: "message-#{@props.messageID}-header"
                message: @props.message
                contacts: ContactGetter.getAll  @props.message
                avatar: ContactGetter.getAvatar @props.message
                createdAt: MessageGetter.getCreatedAt @props.message
                isDraft: @props.isDraft
                isDeleted: @props.isDeleted
                isFlagged: @props.isFlagged
                isUnread: @props.isUnread
                active: @props.isActive,

            if @props.isActive and not @props.isTrashbox
                ToolbarMessage
                    ref         : "message-#{@props.messageID}-toolbar"
                    key         : "message-#{@props.messageID}-toolbar"
                    isFull      : true
                    messageID   : @props.messageID

            if @props.isActive
                MessageContent
                    ref: "message-#{@props.messageID}-content"
                    key: "message-#{@props.messageID}-content"
                    messageID: @props.messageID
                    html: @props.html
                    text: @props.text
                    rich: @props.rich
                    imagesWarning: @props.imagesWarning

            if @props.isActive
                footer
                    ref: "message-#{@props.messageID}-footer"
                    key: "message-#{@props.messageID}-footer"
                    className: 'attachments',
                    ul null,
                    @props.resources.get('preview')?.map (file, index) =>
                        @renderAttachement file, index, true
                    @props.resources.get('binary')?.map (file, index) =>
                        @renderAttachement file, index, false
