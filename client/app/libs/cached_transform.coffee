module.exports = (store, key, args..., transform) ->
    store.__cachedTransforms ?= {}
    cached = store.__cachedTransforms[key]
    sameArgs = true
    if cached
        sameArgs = false for arg, i in cached.args when args[i] isnt arg
        return cached.result if sameArgs

    result = transform()
    store.__cachedTransforms[key] = {args, result}
    return result
