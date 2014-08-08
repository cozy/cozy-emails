{div, ul, li, a, span, i, p} = React.DOM
classer = React.addons.classSet

RouterMixin = require '../mixins/router'
FluxChildMixin = Fluxxor.FluxChildMixin React

module.exports = EmailList = React.createClass
    displayName: 'EmailList'

    mixins: [RouterMixin, FluxChildMixin]

    render: ->
        div id: 'email-list',
            ul className: 'list-unstyled',
                for email, key in @props.emails
                    if email.inReplyTo.length is 0
                        isActive = @props.openEmail? and @props.openEmail.id is email.id
                        @getEmailRender email, key, isActive

    getEmailRender: (email, key, isActive) ->

        classes = classer
            read: email.isRead
            active: isActive

        url = @buildUrl
            direction: 'right'
            action: 'email'
            parameter: email.id

        li className: 'email ' + classes, key: key,
            a href: url,
                i className: 'fa fa-user'
                span className: 'email-participants', @getParticipants email
                div className: 'email-preview',
                    span className: 'email-title', email.subject
                    p null, email.text
                span className: 'email-hour', '23:20'


    getParticipants: (email) ->
        #list = [email.sender].concat email.receivers
        #return list.join ', '
        return email.from + ', ' + email.to
