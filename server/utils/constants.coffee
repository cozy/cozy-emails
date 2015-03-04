
exports.MSGBYPAGE = 30
# safeDestroy parameters (to be tweaked)
# loads 200 ids in memory at once
exports.LIMIT_DESTROY = 200
# loads 30 messages in memory at once
exports.LIMIT_UPDATE = 30
# send 5 request to the DS in parallel
exports.CONCURRENT_DESTROY = 1
# number of IMAP & cozy UID&flags in memory when comparing boxes
exports.FETCH_AT_ONCE = 1000
# maximum number of messages to fetch at once for each box
exports.LIMIT_BY_BOX  = 1000
# accounts refreshs in ms, 5 minutes
exports.REFRESH_INTERVAL = 300000
