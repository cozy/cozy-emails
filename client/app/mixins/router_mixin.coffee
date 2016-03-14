###
    Router mixin.
    Aliases `buildUrl` and `buildClosePanelUrl`
###

Router = require '../router'

Getter =
    # FIXME : router n'existe pas, pkoi ?!
    buildUrl: (options) ->
        Router.prototype.buildUrl options


    #FIXME : supprimer cette méthode
    # Builds the URL (based on options) and redirect to it.
    # If `options` is a string, it will be considered as the target URL.
    redirect: (options) ->
        console.log 'redirect', options
        # url = if typeof options is "string" then options else @buildUrl options
        # Router.prototype.buildUrl url, true

module.exports = Getter
