getAttachmentType = require '../libs/attachment_types'
{Icons} = require '../constants/app_constants'

exports.getFileSize = (file) ->
    length = parseInt file?.length, 10
    if length < 1024
        "#{length} #{t 'length bytes'}"
    else if length < 1024*1024
        "#{0 | length / 1024} #{t 'length kbytes'}"
    else
        "#{0 | length / (1024*1024)} #{t 'length mbytes'}"

exports.getAttachmentIcon = ({contentType}) ->
    type = getAttachmentType contentType
    Icons[type] or 'fa-file-o'
