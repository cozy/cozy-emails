
module.exports =


    getPreviewSize: (state) ->
        state.get('layout').previewSize


    isIntentAvailable: (state) ->
        state.get('layout').intentAvailable


    isToastHidden: (state) ->
        state.get('layout').hidden
