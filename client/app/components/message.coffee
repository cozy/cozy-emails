{div, ul, li, span, i, p, h3, a} = React.DOM
classer = React.addons.classSet

module.exports = React.createClass
    displayName: 'Message'

    getInitialState: -> active: false

    render: ->
        clickHandler = if @props.isLast then null else @onClick

        classes = classer
            message: true
            active: @state.active

        today = moment()
        date = moment @props.message.get 'createdAt'
        if date.isBefore today, 'year'
            formatter = 'DD/MM/YYYY'
        else if date.isBefore today, 'day'
            formatter = 'DD MMMM'
        else
            formatter = 'hh:mm'

        li className: classes, key: @props.key, onClick: clickHandler,
            div className: 'header',
                i className: 'fa fa-user'
                div className: 'participants',
                    span  className: 'sender', @props.message.get 'from'
                    span className: 'receivers', t "mail receivers", {dest: @props.message.get 'to'}
                span className: 'hour', date.format formatter
            div className: 'preview',
                p null, @props.message.get 'text'
            div className: 'content', @props.message.get 'text'
            div className: 'clearfix'

    onClick: (args) ->
        @setState active: not @state.active
