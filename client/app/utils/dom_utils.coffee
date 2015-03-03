
module.exports = DomUtils =

    # Check if an element is inside visible viewport
    # @params DOMElement node
    isVisible: (node) ->
        # Get the element bounding client rect and check if it's inside
        # visible viewport
        rect   = node.getBoundingClientRect()
        height = window.innerHeight or document.documentElement.clientHeight
        width  = window.innerWidth  or document.documentElement.clientWidth
        return rect.bottom <= ( height + 0 ) and rect.top >= 0


