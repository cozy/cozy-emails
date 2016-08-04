{Icons} = require '../constants/app_constants'

RouterGetter = require '../getters/router'
getAttachmentType = require '../libs/attachment_types'

module.exports =

    getMailboxIcon: (params={}) ->
        {account, mailboxID, type} = params
        mailboxID ?= RouterGetter.getMailboxID()

        if type? and (value = Icons[type])
            return {type, value}

        account ?= RouterGetter.getAccount()
        for type, value of Icons
            if mailboxID is account?.get type
                return {type, value}


    getAttachmentIcon: ({contentType}) ->
        type = getAttachmentType contentType
        Icons[type] or 'fa-file-o'


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


    getFileURL: (file) ->
        if file.rawFileObject and not file.url
            return URL.createObjectURL file.rawFileObject
        file.url


    getFileSize: (file) ->
        length = parseInt file?.length, 10
        if length < 1024
            "#{length} #{t 'length bytes'}"
        else if length < 1024*1024
            "#{0 | length / 1024} #{t 'length kbytes'}"
        else
            "#{0 | length / (1024*1024)} #{t 'length mbytes'}"
