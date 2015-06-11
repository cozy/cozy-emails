{ul} = React.DOM
MessageItem = require './message-list-item'
DomUtils     = require '../utils/dom_utils'


module.exports = MessageListBody = React.createClass
    displayName: 'MessageListBody'

    getInitialState: ->
        state =
            messageID: null

    shouldComponentUpdate: (nextProps, nextState) ->
        # we must do the comparison manually because the property "onSelect" is
        # a function (therefore it should not be compared)
        updatedProps = Object.keys(nextProps).filter (prop) =>
            return typeof nextProps[prop] isnt 'function' and
                not (_.isEqual(nextProps[prop], @props[prop]))
        should = not(_.isEqual(nextState, @state)) or updatedProps.length > 0

        return should

    _isActive: (id, cid) ->
        @props.messageID is id or
        @props.displayConversations and cid? and @props.conversationID is cid

    render: ->
        ul className: 'list-unstyled', ref: 'messageList',
            @props.messages.map((message, key) =>
                id = message.get('id')
                cid = message.get('conversationID')

                MessageItem
                    message: message,
                    mailboxID: @props.mailboxID,
                    conversationLengths: @props.conversationLengths?.get(cid),
                    key: key,
                    isActive: @_isActive(id, cid),
                    edited: @props.edited,
                    settings: @props.settings,
                    selected: @props.selected[id]?,
                    login: @props.login
                    displayConversations: @props.displayConversations
                    isTrash: @props.isTrash
                    ref: 'messageItem'
                    onSelect: (val) =>
                        @props.onSelect id, val
            ).toJS()

    componentDidMount: ->
        @_onMount()

    componentDidUpdate: ->
        @_onMount()

    _onMount: ->
        # If selected message has changed, scroll the list to put
        # current message into view
        if @state.messageID isnt @props.messageID
            scrollable = @refs.messageList?.getDOMNode()?.parentNode
            active = document.querySelector("[data-message-id='#{@props.messageID}']")
            if active? and not DomUtils.isVisible(active)
                scroll = scrollable?.scrollTop
                active.scrollIntoView(false)
                # display half of next message
                if scroll isnt @refs.scrollable?.getDOMNode()?.scrollTop
                    scrollable?.scrollTop += active.getBoundingClientRect().height / 2

            @setState messageID: @props.messageID
