
module.exports = FileUtils =

    dataURItoBlob: (dataURI) ->
        if (dataURI.split(',')[0].indexOf('base64') >= 0)
            byteString = atob(dataURI.split(',')[1])
        else
            byteString = window.unescape(dataURI.split(',')[1])
        res =
            mime: dataURI.split(',')[0].split(':')[1].split(';')[0],
            blob: new Uint8Array(byteString.length)
        for i in [0..byteString.length]
            res.blob[i] = byteString.charCodeAt(i)
        return res

    fileToDataURI: (file, cb) ->
        fileReader = new FileReader()
        fileReader.readAsDataURL file
        fileReader.onload = ->
            cb fileReader.result
