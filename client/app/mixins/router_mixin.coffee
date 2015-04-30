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


    # Builds the URL (based on options) and redirect to it.
    # If `options` is a string, it will be considered as the target URL.
    redirect: (options) ->
        url = if typeof options is "string" then options else @buildUrl options
        router.navigate url, true

