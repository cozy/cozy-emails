{div, span, ul, li, table, tbody, tr, td, img, a, i} = React.DOM

AttachmentPreview = require './attachement_preview'
PopupMessageDetails = require './popup_message_details'
ParticipantMixin = require '../mixins/participant_mixin'
ContactLabel = require './contact_label'
messageUtils = require '../utils/message_utils'

{MessageFlags, Tooltips} = require '../constants/app_constants'


module.exports = React.createClass
    displayName: 'MessageHeader'

    #mixins: [
        #ParticipantMixin
    #]

    propTypes:
        message: React.PropTypes.object.isRequired
        isDraft: React.PropTypes.bool
        isDeleted: React.PropTypes.bool


    formatUsers: (users) ->
       return unless users?

       if _.isArray users
           items = []
           for user in users
              items.push ContactLabel
                   contact: user

               items.push ", " if user isnt _.last users
           return items
       else
           return ContactLabel
               contact: user


    getInitialState: ->
        showDetails: false
        showAttachements: false


    render: ->
        avatar = messageUtils.getAvatar @props.message

        div key: "message-header-#{@props.message.get 'id'}",
            if avatar
                div className: 'sender-avatar',
                    img className: 'media-object', src: avatar
            div className: 'infos',
                @renderAddress 'from'
                @renderAddress 'to'
                @renderAddress 'cc'
                div className: 'indicators',
                    if @props.message.get('attachments').length
                        @renderAttachementsIndicator()
                    if MessageFlags.FLAGGED in @props.message.get('flags')
                        i className: 'fa fa-star'
                    if @props.isDraft
                        i className: 'fa fa-edit'
                    if @props.isDeleted
                        i className: 'fa fa-trash'
                div className: 'date',
                    messageUtils.formatDate @props.message.get 'createdAt'
                @renderDetailsPopup()


    renderAddress: (field) ->
        users = @props.message.get field
        return unless users.length

        div
            className: "addresses #{field}",
            key: "address-#{field}",
                if field isnt 'from'
                    span null,
                        t "mail #{field}"
                @formatUsers(users)...


    renderAttachementsIndicator: ->
        attachments = @props.message.get('attachments')?.toJS() or []

        div
            className: 'attachments'
            'aria-expanded': @state.showAttachements
            onClick: (event) -> event.stopPropagation()
            i
                className: 'btn fa fa-paperclip fa-flip-horizontal'
                onClick: @toggleAttachments
                'aria-describedby': Tooltips.OPEN_ATTACHMENTS
                'data-tooltip-direction': 'left'

            div className: 'popup', 'aria-hidden': not @state.showAttachements,
                ul className: null,
                    for file in attachments
                        AttachmentPreview
                            ref: 'attachmentPreview'
                            file: file
                            key: file.checksum
                            preview: false


    renderDetailsPopup: ->
        from = @props.message.get('from')[0]
        to = @props.message.get 'to'
        cc = @props.message.get 'cc'
        reply = @props.message.get('reply-to')?[0]

        row = (id, value, label = false, rowSpan = false) ->
            items = []
            if label
                attrs = className: 'label'
                attrs.rowSpan = rowSpan if rowSpan
                items.push td attrs, t label
            items.push td key: "cell-#{id}", value
            return tr key: "row-#{id}", items...


        div
            className: 'details'
            'aria-expanded': @state.showDetails
            onClick: (event) -> event.stopPropagation()
            i className: 'btn fa fa-caret-down', onClick: @toggleDetails
            div className: 'popup', 'aria-hidden': not @state.showDetails,
                table null,
                    tbody null,
                        row 'from', @formatUsers(from), 'headers from'
                        row 'to', @formatUsers(to[0]), 'headers to', to.length if to.length
                        row "destTo#{key}", @formatUsers(dest) for dest, key in to[1..] if to.length
                        row 'cc', @formatUsers(cc[0]), 'headers cc', cc.length if cc.length
                        row "destCc#{key}", @formatUsers(dest) for dest, key in cc[1..] if cc.length
                        row 'reply', @formatUsers(reply), 'headers reply-to' if reply?
                        row 'created', @props.message.get('createdAt'), 'headers date'
                        row 'subject', @props.message.get('subject'), 'headers subject'


    toggleDetails: ->
        @setState showDetails: not @state.showDetails


    toggleAttachments: ->
        @setState showAttachements: not @state.showAttachements

