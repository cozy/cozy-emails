TIMEOUT = 3000 # 3 s

module.exports = class IntentManager

    constructor : () ->
        @talker = new Talker(window.parent,'*')

    send : (nameSpace,intent, timeout) ->
        @talker.timeout = if timeout then timeout else TIMEOUT
        @talker.send('nameSpace',intent)
