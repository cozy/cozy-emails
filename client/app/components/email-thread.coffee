{div, ul, li, span, i, p, h3, a} = React.DOM
classer = React.addons.classSet

RouterMixin = require '../mixins/router'

module.exports = EmailThread = React.createClass
    displayName: 'EmailThread'

    mixins: [RouterMixin]

    render: ->

        expandUrl = @buildUrl
            direction: 'left'
            action: 'email'
            parameter: @props.email.id
            fullWidth: true

        closeUrl = @buildClosePanelUrl @props.layout

        div id: 'email-thread',

            #ul className: 'nav nav-tabs nav-justified',
            #    li className: 'active',
            #        a href: '#', 'Responsive Cozy Emails'
            #        span className: 'close', '&times;'
            #    li null,
            #        a href: '#', 'Responsive Cozy Emails'
            #        span className: 'close', '&times;'
            #    li null,
            #        a href: '#', 'Responsive Cozy Emails'
            #        span className: 'close', '&times;'
            #    li null,
            #        a href: '#', 'Responsive Cozy Emails'
            #        span className: 'close', '&times;'
            #    li null,
            #        a href: '#', 'Responsive Cozy Emails'
            #        span className: 'close', '&times;'

            h3 null,
                a href: expandUrl, className: 'expand',
                    i className: 'fa fa-angle-left'
                @props.email.title
                a href: closeUrl, className: 'close-email',
                    i className:'fa fa-times'
            ul className: 'email-thread list-unstyled',
                li className: 'email unread',
                    div className: 'email-header',
                        i className: 'fa fa-user'
                        div className: 'email-participants',
                            span  className: 'sender', 'Joseph'
                            span className: 'receivers', 'À Frank Rousseau'
                        span className: 'email-hour', @props.email.date
                    div className: 'email-preview',
                        p null, @props.email.content
                    div className: 'email-content', @props.email.content
                    div className: 'clearfix'
