# Guess simple attachment type from mime type.
module.exports =  (type) ->
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
