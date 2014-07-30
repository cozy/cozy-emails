module.exports =

    showRoute: (name, leftPanelInfo, rightPanelInfo) ->
        @dispatch 'SHOW_ROUTE', {name, leftPanelInfo, rightPanelInfo}
