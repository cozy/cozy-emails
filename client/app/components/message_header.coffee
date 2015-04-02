{div, span, table, tbody, tr, td, img, a, i} = React.DOM
MessageUtils = require '../utils/message_utils'

ContactStore   = require '../stores/contact_store'

{MessageFlags} = require '../constants/app_constants'


module.exports = React.createClass
    displayName: 'MessageHeader'

    propTypes:
        message: React.PropTypes.object.isRequired


    getInitialState: ->
        detailled: false


    render: ->
        avatar = MessageUtils.getAvatar @props.message

        div null,
            if avatar
                div className: 'sender-avatar',
                    img className: 'media-object', src: avatar
            div className: 'infos',
                @renderAddress 'from'
                @renderAddress 'to'
                @renderAddress 'cc'
                div className: 'indicators',
                    if @props.message.get('attachments').length
                        i className: 'fa fa-paperclip fa-flip-horizontal'
                    if MessageFlags.FLAGGED in @props.message.get('flags')
                        i className: 'fa fa-star'
                div className: 'date',
                    MessageUtils.formatDate @props.message.get 'createdAt'
                @renderDetailsPopup()


    formatUsers: (users) ->
        return unless users?

        format = (user) ->
            items = []
            if user.name
                items.push "#{user.name} "
                items.push span className: 'contact-address',
                    i className: 'fa fa-angle-left'
                    user.address
                    i className: 'fa fa-angle-right'
            else
                items.push user.address
            return items

        if _.isArray users
            items = []
            for user in users
                contact = ContactStore.getByAddress user.address
                items.push if contact?
                    a
                        target: '_blank'
                        href: "/#apps/contacts/contact/#{contact.get 'id'}"
                        onClick: (event) -> event.stopPropagation()
                        format(user)

                else
                    span
                        className: 'participant'
                        onClick: (event) -> event.stopPropagation()
                        format(user)

                items.push ", " if user isnt _.last(users)
            return items
        else
            return format(users)


    renderAddress: (field) ->
        users = @props.message.get field
        return unless users.length

        div className: "addresses #{field}",
            if field isnt 'from'
                span null,
                    t "mail #{field}"
            @formatUsers(users)...


    renderDetailsPopup: ->
        from = @props.message.get('from')[0]
        to = @props.message.get 'to'
        cc = @props.message.get 'cc'
        reply = @props.message.get('reply-to')?[0]

        row = (value, label = false, rowSpan = false) ->
            items = []
            if label
                attrs = className: 'label'
                attrs.rowSpan = rowSpan if rowSpan
                items.push td attrs, t label
            items.push td null, value
            return tr null, items...


        div
            className: 'details', 'aria-expanded': @state.detailled
            onClick: (event) -> event.stopPropagation()
            i className: 'btn fa fa-caret-down', onClick: @toggleDetails
            div className: 'popup', 'aria-hidden': !@state.detailled,
                table null,
                    tbody null,
                        row @formatUsers(from), 'headers from'
                        row @formatUsers(to[0]), 'headers to', to.length if to.length
                        row @formatUsers(dest) for dest in to[1..] if to.length
                        row @formatUsers(cc[0]), 'headers cc', cc.length if cc.length
                        row @formatUsers(dest) for dest in cc[1..] if cc.length
                        row @formatUsers(reply), 'headers reply-to' if reply?
                        row @props.message.get('createdAt'), 'headers date'
                        row @props.message.get('subject'), 'headers subject'

    toggleDetails: ->
        @setState detailled: !@state.detailled
