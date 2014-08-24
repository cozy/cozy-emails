Fluxxor = require 'fluxxor'
React = require 'react/addons'
Immutable = require 'immutable'
moment = require 'moment'

{div, ul, li, a, span, i, p} = React.DOM
classer = React.addons.classSet

RouterMixin = require '../mixins/RouterMixin'
FluxChildMixin = Fluxxor.FluxChildMixin React

module.exports = EmailList = React.createClass
    displayName: 'EmailList'

    mixins: [RouterMixin, FluxChildMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not Immutable.is(nextProps.emails, @props.emails) or
               not Immutable.is(nextProps.openEmail, @props.openEmail)

    render: ->
        div id: 'email-list',
            ul className: 'list-unstyled',
                @props.emails.map (email, key) =>
                    # only displays initial email of a thread
                    if email.inReplyTo.length is 0
                        isActive = @props.openEmail? and
                                   @props.openEmail.id is email.id
                        @getEmailRender email, key, isActive
                .toJS()

    getEmailRender: (email, key, isActive) ->
        classes = classer
            read: email.isRead
            active: isActive

        url = @buildUrl
            direction: 'right'
            action: 'email'
            parameters: email.id

        today = moment()
        date = moment email.createdAt
        if date.isBefore today, 'year'
            formatter = 'DD/MM/YYYY'
        else if date.isBefore today, 'day'
            formatter = 'DD MMMM'
        else
            formatter = 'hh:mm'

        li className: 'email ' + classes, key: key,
            a href: url,
                i className: 'fa fa-user'
                span className: 'email-participants', @getParticipants email
                div className: 'email-preview',
                    span className: 'email-title', email.subject
                    p null, email.text
                span className: 'email-hour', date.format formatter


    getParticipants: (email) ->
        #list = [email.sender].concat email.receivers
        #return list.join ', '
        return email.from + ', ' + email.to
