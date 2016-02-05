
exports.MSGBYPAGE = 30
# safeDestroy parameters (to be tweaked)
# number of ids loaded in memory at once
exports.LIMIT_DESTROY = 200
# number of messages loaded in memory at once
exports.LIMIT_UPDATE = 50
# number of request sent to the DS in parallel
exports.CONCURRENT_DESTROY = 1
# number of IMAP & cozy UID&flags in memory when comparing boxes
exports.FETCH_AT_ONCE = 10000
# maximum number of messages to fetch at once for each box
exports.LIMIT_BY_BOX  = 1000

exports.RFC6154 =
    draftMailbox:   '\\Drafts'
    sentMailbox:    '\\Sent'
    trashMailbox:   '\\Trash'
    allMailbox:     '\\All'
    junkMailbox:    '\\Junk'
    flaggedMailbox: '\\Flagged'
