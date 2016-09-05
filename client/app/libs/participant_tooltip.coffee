jQuery = require('jquery')
t = window.t

# To keep HTML markup light, create the contact tooltip dynamicaly
# on mouse over
# options:
#  - container  : tooltip container
#  - delay      : nb of miliseconds to wait before displaying tooltip
#  - showOnClick: set to true to display tooltip when clicking on element
module.exports.tooltip = (node, contact, address, onAdd) ->
    timeout = null
    doAdd = (e) ->
        e.preventDefault()
        e.stopPropagation()
        onAdd address
    addTooltip = ->
        if node.dataset.tooltip
            return
        node.dataset.tooltip = true
        contact = getContact address
        avatar  = contact?.get 'avatar'
        add   = ''
        image = ''
        if contact?
            if avatar?
                image = "<img class='avatar' src=#{avatar}>"
            else
                image = "<div class='no-avatar'>?</div>"
            id = contact.get('id')
            image = """
            <div class="tooltip-avatar">
              <a href="/#apps/contacts/contact/#{id}" target="blank">
                #{image}
              </a>
            </div>
            """
        else
            if onAdd?
                add = """
                <p class="tooltip-toolbar">
                  <button class="btn btn-cozy btn-add" type="button">
                  #{t 'contact button label'}
                  </button>
                </p>
                """
        template = """
            <div class="tooltip" role="tooltip">
                <div class="tooltip-arrow"></div>
                <div class="tooltip-content">
                    #{image}
                    <div>
                    #{address.name}
                    #{if address.name then '<br>' else ''}
                    &lt;#{address.address}&gt;
                    </div>
                    #{add}
                </div>
            </div>'
            """
        options =
            title: address.address
            template: template
            trigger: 'manual'
            placement: 'auto top'
            container: options.container or node.parentNode
        jQuery(node).tooltip(options).tooltip('show')
        tooltipNode = jQuery(node).data('bs.tooltip').tip()[0]
        if parseInt(tooltipNode.style.left, 10) < 0
            tooltipNode.style.left = 0
        rect = tooltipNode.getBoundingClientRect()
        mask = document.createElement 'div'
        mask.classList.add 'tooltip-mask'
        mask.style.top    = (rect.top - 8) + 'px'
        mask.style.left   = (rect.left - 8) + 'px'
        mask.style.height = (rect.height + 32) + 'px'
        mask.style.width  = (rect.width  + 16) + 'px'
        document.body.appendChild mask
        mask.addEventListener 'mouseout', (e) ->
            if not ( rect.left < e.pageX < rect.right) or
            not ( rect.top  < e.pageY < rect.bottom)
                mask.parentNode.removeChild mask
                removeTooltip()
        if onAdd?
            addNode = tooltipNode.querySelector('.btn-add')
            if addNode?
                addNode.addEventListener 'click', doAdd
    removeTooltip = ->
        addNode = node.querySelector('.btn-add')
        if addNode?
            addNode.removeEventListener 'click', doAdd
        delete node.dataset.tooltip
        jQuery(node).tooltip('destroy')

    node.addEventListener 'mouseover', ->
        timeout = setTimeout ->
            addTooltip()
        , options.delay or 1000
    node.addEventListener 'mouseout', ->
        clearTimeout timeout
    if options.showOnClick
        node.addEventListener 'click', (event) ->
            event.stopPropagation()
            addTooltip()
