module.exports.initialize = ->
    if window.settings?.desktopNotifications and window.Notification
        Notification.requestPermission (status) ->
            # This allows to use Notification.permission
            # with Chrome/Safari
            if Notification.permission isnt status
                Notification.permission = status
