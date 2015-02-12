{span, a, i} = React.DOM
MessageUtils   = require '../utils/message_utils'
ContactStore   = require '../stores/contact_store'

Participant = React.createClass
    displayName: 'Participant'

    render: ->
        if not @props.address?
            span null
        else
            span
                className: 'address-item'
                'data-toggle': "tooltip"
                ref: 'participant'
                title: @props.address.address,
                key: @props.key,
                MessageUtils.displayAddress @props.address

    # To keep HTML markup light, create the contact tooltip dynamicaly
    # on mouse over
    tooltip: ->
        if @refs.participant?
            node  = @refs.participant.getDOMNode()
            delay = null
            onAdd = (e) =>
                e.preventDefault()
                e.stopPropagation()
                @props.onAdd @props.address
            addTooltip = (e) =>
                if node.dataset.tooltip
                    return
                node.dataset.tooltip = true
                contact = ContactStore.getByAddress @props.address.address
                avatar  = contact?.get 'avatar'
                if avatar?
                    image = "<img class='avatar' src=#{avatar}>"
                else
                    image = "<i class='avatar fa fa-user' />"
                if contact?
                    image = """
                    <a href="#apps/contacts/contact/#{contact.get 'id'}" target="blank">
                        #{image}
                    </a>
                    """
                if @props.onAdd?
                    add = """
                    <a class='address-add'>
                        <i class='fa fa-plus' />
                    </a>
                    """
                else
                    add = ''
                template = """
                    <div class="tooltip" role="tooltip">
                        <div class="tooltip-arrow"></div>
                        <div>
                            #{image}
                            #{@props.address.address}
                            #{add}
                        </div>
                    </div>'
                    """
                options =
                    template: template
                    trigger: 'manual'
                    container: "[data-reactid='#{node.dataset.reactid}']"
                jQuery(node).tooltip(options).tooltip('show')
                tooltipNode = jQuery(node).data('bs.tooltip').tip()[0]
                if parseInt(tooltipNode.style.left, 10) < 0
                    tooltipNode.style.left = 0
                rect = tooltipNode.getBoundingClientRect()
                mask = document.createElement 'div'
                mask.classList.add 'tooltip-mask'
                mask.style.top    = (rect.top - 2) + 'px'
                mask.style.left   = (rect.left - 2) + 'px'
                mask.style.height = (rect.height + 16) + 'px'
                mask.style.width  = (rect.width  + 4) + 'px'
                document.body.appendChild mask
                mask.addEventListener 'mouseout', (e) ->
                    if not ( rect.left < e.pageX < rect.right) or
                       not ( rect.top  < e.pageY < rect.bottom)
                        mask.parentNode.removeChild mask
                        removeTooltip()
                if @props.onAdd?
                    addNode = tooltipNode.querySelector('.address-add')
                    addNode.addEventListener 'mouseover', ->
                    addNode.addEventListener 'click', onAdd
            removeTooltip = ->
                addNode = node.querySelector('.address-add')
                if addNode?
                    addNode.removeEventListener 'click', onAdd
                delete node.dataset.tooltip
                jQuery(node).tooltip('destroy')

            node.addEventListener 'mouseover', ->
                delay = setTimeout ->
                    addTooltip()
                , 5000
            node.addEventListener 'mouseout', ->
                clearTimeout delay
            node.addEventListener 'click', (event) ->
                event.stopPropagation()
                addTooltip()

    componentDidMount: ->
        if @props.tooltip
            @tooltip()

    componentDidUpdate: ->
        if @props.tooltip
            @tooltip()

Participants = React.createClass
    displayName: 'Participants'

    render: ->
        span className: 'address-list',
            if @props.participants
                for address, key in @props.participants
                    span key: key, className: null,
                        Participant {key, address, onAdd: @props.onAdd, tooltip: @props.tooltip}
                        if key < ( @props.participants.length - 1)
                            span null, ', '

module.exports = Participants
