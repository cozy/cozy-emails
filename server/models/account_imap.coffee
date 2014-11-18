Account = require './account'
Mailbox = require './mailbox'
ImapScheduler = require '../processes/imap_scheduler'
ImapReporter = require '../processes/imap_reporter'
Promise = require 'bluebird'
log = require('../utils/logging')(prefix: 'models:account_imap')
Compiler    = require 'nodemailer/src/compiler'
_ = require 'lodash'
# functions of an account linked to imap


Account::makeImapConfig = ->
    id: @_id
    user: @login
    label: @label
    password: @password
    host: @imapServer
    port: parseInt @imapPort
    tls: not @imapSSL? or @imapSSL
    tlsOptions: rejectUnauthorized: false

# static function, we have 1 ImapScheduler by Account
Account::getScheduler = ->
    if @id then ImapScheduler.instanceFor @id, this
    else Promise.resolve new ImapScheduler @makeImapConfig()

Account::doASAP = (gen) ->
    @getScheduler().then (scheduler) ->
        scheduler.doASAP gen

Account::imap_getBoxes = ->
    @doASAP (imap) -> imap.getBoxes()

Account::testIMAPConnection = ->
    @doASAP (imap) -> Promise.resolve 'OK'

Account::imap_refreshBoxes = ->
    account = this

    # get cozy & imap boxes and store them in closure
    Promise.join Mailbox.getBoxes(@id), @imap_getBoxes(),
    (cozyBoxes, imapBoxes) ->
        toFetch = []
        toDestroy = []
        # find new imap boxes
        boxToAdd = imapBoxes.filter (box) ->
            not _.findWhere(cozyBoxes, path: box.path)

        # discrimate cozyBoxes to fetch and to remove
        for cozyBox in cozyBoxes
            if _.findWhere(imapBoxes, path: cozyBox.path)
                toFetch.push cozyBox
            else
                toDestroy.push cozyBox

        # create new boxes in cozy
        Promise.serie boxToAdd, (box) ->
            box.accountID = account.id
            Mailbox.createPromised box
            .then (createdCozyBox) -> toFetch.push createdCozyBox

        .then -> return [toFetch, toDestroy]


# Public: refresh one account
# register a 'account-fetch' task in {ImapReporter}
#
# limitByBox - the maximum {Number} of message to fetch at once for each box
# onlyFavorites - {Boolean} fetch messages only for favorite mailboxes
#
# Returns a {Promise} for task completion
Account::imap_fetchMails = (limitByBox, onlyFavorites = false) ->
    account = this

    @imap_refreshBoxes()
    .spread (toFetch, toDestroy) =>

        if onlyFavorites
            toFetch = toFetch.filter (box) -> box.id in account.favorites

        log.info "FETCHING ACCOUNT ", @label, ":", toFetch.length, "BOXES"
        log.info "   ", toDestroy.length, "BOXES TO DESTROY"
        reporter = ImapReporter.accountFetch this, toFetch.length + 1

        # fetch INBOX first
        toFetch.sort (a, b) ->
            return if a.label is 'INBOX' then 1
            else return -1

        Promise.serie toFetch, (box) ->
            box.imap_fetchMails limitByBox
            .catch (err) -> reporter.onError err
            .tap         -> reporter.addProgress 1

        # we remove deleted boxes after fetch, so moved boxes are fast-fetched
        .then ->
            Promise.serie toDestroy, (box) ->
                box.destroyAndRemoveAllMessages()

        .finally -> reporter.onDone()

# Public: create a mail in the given box
# used for drafts
#
# box - the {Mailbox} to create mail into
# message - a {Message} to create
#
# Returns a {Promise} for the box & UID of the created mail
Account::imap_createMail = (box, message) ->

    # compile the message to text
    # @todo, promisfy somewhere else
    new Promise (resolve, reject) ->
        mailbuilder = new Compiler(message).compile()
        mailbuilder.build (err, buffer) ->
            if err then reject err
            else resolve buffer

    # save the message in IMAP server
    .then (buffer) =>
        @doASAP (imap) ->
            imap.append buffer,
                mailbox: box.path
                flags: message.flags

    # returns box & uid of the new message
    .then (uid) -> return [box, uid]

# Public: remove a mail in the given box
# used for drafts
#
# account - the {Account} to delete mail from
# box - the {Mailbox} to delete mail from
# mail - a {Message} to create
#
# Returns a {Promise} for the UID of the created mail

# Public: create a box in the account
#
# account - the {Account} to create box in
# path - {String} the full path  of the mailbox
#
# Returns a {Promise} for task completion
Account::imap_createBox = (path) ->
    return Promise.resolve {path: path} if @isTest()
    @doASAP (imap) -> imap.addBox path

# Public: rename/move a box in the account
#
# oldpath - {String} the full current path of the mailbox
# newpath - {String} the full path to move the box to
#
# Returns a {Promise} for task completion
Account::imap_renameBox = (oldpath, newpath) ->
    return Promise.resolve {path: newpath} if @isTest()
    @doASAP (imap) -> imap.renameBox oldpath, newpath

# Public: delete a box in the account
#
# account - the {Account} to delete the box from
# path - {String} the full path  of the mailbox
#
# Returns a {Promise} for task completion
Account::imap_deleteBox = (path) ->
    return Promise.resolve null if @isTest()
    @doASAP (imap) -> imap.delBox path


Account::imap_scanBoxesForSpecialUse = (boxes) ->
    useRFC6154 = false
    inboxMailbox = null
    boxAttributes = Object.keys Mailbox.RFC6154

    boxes.map (box) =>
        if box.isInbox()
            # save it in scope, so we dont erase it
            inboxMailbox = box.id

        else if type = box.RFC6154use()
            unless useRFC6154
                useRFC6154 = true
                # remove previous guesses
                for attribute in boxAttributes
                    @[attribute] = null
            log.debug 'found', type
            @[type] = box.id

        # do not attempt fuzzy match if the server uses RFC6154
        else if not useRFC6154 and type = box.guessUse()
            log.debug 'found', type, 'guess'
            @[type] = box.id

        return box

    # pick the default 4 favorites box
    priorities = [
        'inboxMailbox', 'allMailbox',
        'sentMailbox', 'draftMailbox'
    ]

    @inboxMailbox = inboxMailbox
    @favorites = []

    # see if we have some of the priorities box
    for type in priorities when id = @[type]
        @favorites.push id

    # if we dont have our 4 favorites, pick at random
    for box in boxes when @favorites.length < 4
        if box.id not in @favorites and '\\NoSelect' not in box.attribs
            @favorites.push box.id

    @savePromised()