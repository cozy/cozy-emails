module.exports.initDesktopNotifications = ->
    return unless window.settings.desktopNotifications and window.Notification

    Notification.requestPermission (status) ->
        # This allows to use Notification.permission with Chrome/Safari
        Notification.permission = status if Notification.permission isnt status
