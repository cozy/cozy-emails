
module.exports = DomUtils =

    isVisible: (node, before) ->
        margin = if before then 40 else 0
        rect   = node.getBoundingClientRect()
        height = window.innerHeight or document.documentElement.clientHeight
        width  = window.innerWidth  or document.documentElement.clientWidth
        return rect.bottom <= ( height + 0 ) and rect.top >= 0


