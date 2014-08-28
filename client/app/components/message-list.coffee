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
        curpage = parseInt @props.pageNum, 10
        nbpages = Math.ceil @props.messagesCount, @props.messagesPerPage
        nbpages++
        div className: 'message-list',
            @getPagerRender(curpage, nbpages),
            if @props.messages.count() is 0
                p null, t "list empty"
            else
                ul className: 'list-unstyled',
                    @props.messages.map (message, key) =>
                        # only displays initial email of a thread
                        if true # @FIXME Mage conversation # message.get('inReplyTo').length is 0
                            isActive = @props.openMessage? and
                                       @props.openMessage.get('id') is message.get('id')
                            @getMessageRender message, key, isActive
                    .toJS()
            @getPagerRender(curpage, nbpages),

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

    getPagerRender: (curpage, nbpages) ->
        classFirst = if curpage is 1 then 'disabled' else ''
        classLast  = if curpage is nbpages then 'disabled' else ''
        if nbpages < 11
            minPage = 1
            maxPage = nbpages
        else
            minpage = if curpage < 5 then 1 else curpage - 2
            maxpage = minpage + 4
            if maxpage > nbpages
                maxpage = nbpages
        if (@props.mailboxID)
            urlFirst = @buildUrl
                direction: 'left'
                action: 'account.mailbox.messages'
                parameters: [@props.accountID, @props.mailboxID, 1]
            urlLast = @buildUrl
                direction: 'left'
                action: 'account.mailbox.messages'
                parameters: [@props.accountID, @props.mailboxID, nbpages]
        else
            urlFirst = @buildUrl
                direction: 'left'
                action: 'account.messages'
                parameters: [@props.accountID, @props.mailboxID, 1]
            urlLast = @buildUrl
                direction: 'left'
                action: 'account.messages'
                parameters: [@props.accountID, nbpages]
        ul className: 'pagination',
            li className: classFirst,
                a href: urlFirst, '«'
            if minpage > 1
                li className: 'disabled',
                    a href: urlFirst, '…'
            for j in [minpage..maxpage] by 1
                classCurr = if j is curpage then 'active' else ''
                if (@props.mailboxID)
                    urlCurr = @buildUrl
                        direction: 'left'
                        action: 'account.mailbox.messages'
                        parameters: [@props.accountID, @props.mailboxID, j]
                else
                    urlCurr = @buildUrl
                        direction: 'left'
                        action: 'account.messages'
                        parameters: [@props.accountID, j]
                li className: classCurr, key: j,
                    a href: urlCurr, j
            if maxpage < nbpages
                li className: 'disabled',
                    a href: urlFirst, '…'
            li className: classLast,
                a href: urlLast, '»'

    getParticipants: (message) -> "#{message.get 'from'}, #{message.get 'to'}"
