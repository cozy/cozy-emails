
module.exports = DomUtils =

    # Check if an element is inside visible viewport
    # @params DOMElement node
    isVisible: (node) ->
        # Get the element bounding client rect and check if it's inside
        # visible viewport
        rect   = node.getBoundingClientRect()
        height = window.innerHeight or document.documentElement.clientHeight
        width  = window.innerWidth  or document.documentElement.clientWidth
        if height is 0 or width is 0
            # when iframe is in background, height and width are 0
            # so prevent to always return true when application is not
            # in foreground
            return false
        else
            return rect.bottom <= ( height + 0 ) and rect.top >= 0


