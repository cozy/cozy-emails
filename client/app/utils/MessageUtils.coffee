module.exports =

    displayAddresses: (addresses, full = false) ->
        if not addresses?
            return ""

        res = []
        for item in addresses
            if not item?
                break
            if full
                if item.name? and item.name isnt ""
                    res.push "\"#{item.name}\" <#{item.address}>"
                else
                    res.push "#{item.address}"
            else
                if item.name? and item.name isnt ""
                    res.push item.name
                else
                    res.push item.address.split('@')[0]
        return res.join ", "

    generateReplyText: (text) ->
        text = text.split '\n'
        res  = []
        text.forEach (line) ->
            res.push "> #{line}"
        return res.join "\n"

    getAttachmentType: (type) ->
        sub = type.split '/'
        switch sub[0]
            when 'audio', 'image', 'text', 'video'
                return sub[0]
            when "application"
                switch sub[1]
                    when "vnd.ms-excel",\
                         "vnd.oasis.opendocument.spreadsheet",\
                         "vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                        return "spreadsheet"
                    when "msword",\
                         "vnd.ms-word",\
                         "vnd.oasis.opendocument.text",\
                         "vnd.openxmlformats-officedocument.wordprocessingml.document"
                        return "word"
                    when "vns.ms-powerpoint",\
                         "vnd.oasis.opendocument.presentation",\
                         "vnd.openxmlformats-officedocument.presentationml.presentation"
                        return "presentation"

                    when "pdf" then return sub[1]
                    when "gzip", "zip" then return 'archive'
