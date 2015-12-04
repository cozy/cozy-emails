module.exports = discovery2Fields = (provider) ->
    infos = {}

    # Set values depending on given providers.
    for server in provider

        if server.type is 'imap' and not infos.imapServer?
            infos.imapServer = server.hostname
            infos.imapPort = server.port

            if server.socketType is 'SSL'
                infos.imapSSL = true
                infos.imapTLS = false

            else if server.socketType is 'STARTTLS'
                infos.imapSSL = false
                infos.imapTLS = true

            else if server.socketType is 'plain'
                infos.imapSSL = false
                infos.imapTLS = false

        if server.type is 'smtp' and not infos.smtpServer?
            infos.smtpServer = server.hostname
            infos.smtpPort = server.port

            if server.socketType is 'SSL'
                infos.smtpSSL = true
                infos.smtpTLS = false

            else if server.socketType is 'STARTTLS'
                infos.smtpSSL = false
                infos.smtpTLS = true

            else if server.socketType is 'plain'
                infos.smtpSSL = false
                infos.smtpTLS = false

    # Set default values if providers didn't give required infos.

    unless infos.imapServer?
        infos.imapServer = ''
        infos.imapPort   = '993'

    unless infos.smtpServer?
        infos.smtpServer = ''
        infos.smtpPort   = '465'

    unless infos.imapSSL
        switch infos.imapPort
            when '993'
                infos.imapSSL = true
                infos.imapTLS = false
            else
                infos.imapSSL = false
                infos.imapTLS = false

    unless infos.smtpSSL
        switch infos.smtpPort
            when '465'
                infos.smtpSSL = true
                infos.smtpTLS = false
            when '587'
                infos.smtpSSL = false
                infos.smtpTLS = true
            else
                infos.smtpSSL = false
                infos.smtpTLS = false

    infos.isGmail = infos.imapServer is 'imap.googlemail.com'

    return infos
