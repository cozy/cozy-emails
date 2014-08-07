###
    Router mixin.
    Aliases `buildUrl` and `buildClosePanelUrl`
###

router = window.router

module.exports =

    buildUrl: (options) ->
        router.buildUrl.call router, options

    buildClosePanelUrl: (direction) ->
        router.buildClosePanelUrl.call router, direction



