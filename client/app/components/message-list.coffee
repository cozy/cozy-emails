{div, ul, li, a, span, i, p} = React.DOM
classer = React.addons.classSet

RouterMixin = require '../mixins/RouterMixin'

module.exports = React.createClass
    displayName: 'MessageList'

    mixins: [RouterMixin]

    shouldComponentUpdate: (nextProps, nextState) ->
        return not Immutable.is(nextProps.messages, @props.messages) or
               not Immutable.is(nextProps.openMessage, @props.openMessage)

    render: ->
        div className: 'message-list',
            if @props.messages.count() is 0
                t "list empty"
            else
                ul className: 'list-unstyled',
                    @props.messages.map (message, key) =>
                        # only displays initial email of a thread
                        if message.get('inReplyTo').length is 0
                            isActive = @props.openMessage? and
                                       @props.openMessage.get('id') is message.get('id')
                            @getMessageRender message, key, isActive
                    .toJS()

    getMessageRender: (message, key, isActive) ->
        classes = classer
            read: message.get 'isRead'
            active: isActive

        url = @buildUrl
            direction: 'right'
            action: 'message'
            parameters: message.get 'id'

        today = moment()
        date = moment message.get 'createdAt'
        if date.isBefore today, 'year'
            formatter = 'DD/MM/YYYY'
        else if date.isBefore today, 'day'
            formatter = 'DD MMMM'
        else
            formatter = 'hh:mm'

        li className: 'message ' + classes, key: key,
            a href: url,
                i className: 'fa fa-user'
                span className: 'participants', @getParticipants message
                div className: 'preview',
                    span className: 'title', message.get 'subject'
                    p null, message.get 'text'
                span className: 'hour', date.format formatter


    getParticipants: (message) -> "#{message.get 'from'}, #{message.get 'to'}"
