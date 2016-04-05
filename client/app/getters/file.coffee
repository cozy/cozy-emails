_ = require 'lodash'

{Icons} = require '../constants/app_constants'

RouterStore = require '../stores/router_store'

module.exports =

    getMailboxIcon: (params={}) ->
        {account, mailboxID, type} = params
        mailboxID ?= RouterStore.getMailboxID()

        if type? and (value = Icons[type])
            return {type, value}

        account ?= RouterStore.getAccount()
        for type, value of Icons
            if mailboxID is account?.get type
                return {type, value}


    getAttachmentIcon: ({contentType}) ->
        type = @getAttachmentType contentType
        Icons[type] or 'fa-file-o'


    # Guess simple attachment type from mime type.
    getAttachmentType: (type) ->
        switch (result = type?.split('/'))[0]

            when 'audio', 'image', 'text', 'video'
                return result[0]

            when "application"
                switch result[1]

                    when "vnd.ms-excel",\
                         "vnd.oasis.opendocument.spreadsheet",\
                         "vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                        return "spreadsheet"

                    when "msword",\
                         "vnd.ms-word",\
                         "vnd.oasis.opendocument.text",\
                         "vnd.openxmlformats-officedocument.wordprocessingm" + \
                         "l.document"
                        return "word"

                    when "vns.ms-powerpoint",\
                         "vnd.oasis.opendocument.presentation",\
                         "vnd.openxmlformats-officedocument.presentationml." + \
                         "presentation"
                        return "presentation"

                    when "pdf"
                        return result[1]

                    when "gzip", "zip"
                        return 'archive'


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
