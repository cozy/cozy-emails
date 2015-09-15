XHRUtils = require '../utils/xhr_utils'

ActivityUtils = (options) ->

    activity = {}

    XHRUtils.activityCreate options, (error, res) ->
        if error
            activity.onerror.call(error)
        else
            activity.onsuccess.call(res)

    return activity

module.exports = ActivityUtils
