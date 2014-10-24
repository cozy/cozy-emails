americano = require 'americano-cozy'
Promise = require 'bluebird'
_ = require 'lodash'

module.exports = Mailbox = americano.getModel 'Mailbox',
    accountID: String        # Parent account
    label: String            # Human readable label
    path: String             # IMAP path
    tree: (x) -> x           # Normalized path as Array
    delimiter: String        # delimiter between this box and its children
    uidvalidity: Number      # Imap UIDValidity
    persistentUIDs: Boolean  # Imap persistentUIDs
    attribs: (x) -> x        # [String] Attributes of this folder

Message = require './message'
log = require('../utils/logging')(prefix: 'models:mailbox')


# map of account's attributes -> RFC6154 special use box attributes
Mailbox.RFC6154 =
    draftMailbox:   '\\Drafts'
    sentMailbox:    '\\Sent'
    trashMailbox:   '\\Trash'
    allMailbox:     '\\All'
    spamMailbox:    '\\Junk'
    flaggedMailbox: '\\Flagged'

Mailbox::isInbox = -> @path is 'INBOX'

Mailbox::RFC6154use = ->
    for field, attribute of Mailbox.RFC6154
        if attribute in @attribs
            return field

Mailbox::guessUse = ->
    path = @path.toLowerCase()
    if 0 is path.indexOf 'sent'
        return 'sentMailbox'
    else if 0 is path.indexOf 'draft'
        return 'draftMailbox'
    else if 0 is path.indexOf 'flagged'
        return 'flaggedMailbox'
    else if 0 is path.indexOf 'trash'
        return 'trashMailbox'
    # @TODO add more


# Public: find selectable mailbox for an account ID
# as an array
#
# accountID - id of the account
#
# Returns a {Promise} for [{Mailbox}]
Mailbox.getBoxes = (accountID) ->
    Mailbox.rawRequestPromised 'treeMap',
        startkey: [accountID]
        endkey: [accountID, {}]
        include_docs: true

    .map (row) -> new Mailbox row.doc
    .filter (box) -> '\\Noselect' not in box.attribs

# Public: get this mailbox's children mailboxes
#
# Returns a {Promise} for [{Mailbox}]
Mailbox::getChildren = ->
    Mailbox.rawRequestPromised 'treemap',
        startkey: [@accountID].concat @tree, ''
        endkey: [@accountID].concat @tree, {}
        include_docs: true

    .map (row) -> new Mailbox row.doc


# Public: build a tree of the mailboxes
#
# accountID - id of the account
#
# Returns a {Promise} for the tree
Mailbox.getClientTree = (accountID) ->

    out = []
    byPath = {}
    DELIMITER = '/|/'

    Mailbox.rawRequestPromised 'treeMap',
        startkey: [accountID]
        endkey: [accountID, {}]
        include_docs: true

    .each (row) ->
        path = row.key[1..] # remove accountID
        # we keep a reference by path to easily find parent
        box = byPath[path.join DELIMITER] = _.pick row.doc, 'label', 'attribs'

        box.id = row.id
        box.children = []

        if path.length is 1 # first level box
            out.push box
        else
            # this is a submailbox,  we find its parent
            # by path and append it
            parentPath = path[0..-2].join DELIMITER
            if byPath[parentPath]?
                byPath[parentPath].children.push box
            else
                # this should never happen
                log.error "NO MAILBOX of path #{parentPath} in #{accountID}"

    .return out


# Public: destroy mailboxes by their account ID
#
# accountID - id of the account to destroy mailboxes from
#
# Returns a {Promise} for mailboxes destroyed completion
Mailbox.destroyByAccount = (accountID) ->
    Mailbox.rawRequestPromised 'treemap',
            startkey: [accountID]
            endkey: [accountID, {}]

    .serie (row) ->
        new Mailbox(id: row.id).destroyPromised()
        # if one box fail to delete, we keep going
        .catch (err) ->
            log.error "Fail to delete box", err.stack or err


# rename this mailbox and its children
#
# newPath - the new path
# newLabel - the new label
#
# Returns a {Promise} for updated box
Mailbox::renameWithChildren = (newPath, newLabel) ->
    depth = @tree.length - 1
    path = @path

    @getChildren()
    .then (children) ->

        @label = newLabel
        @path = newPath
        @tree[depth] = newLabel
        @savePromised()
        .then ->
            Promise.serie children, (child) ->
                child.path = child.path.replace path, newPath
                child.tree[depth] = newLabel
                child.savePromised()

# Public: destroy a mailbox and sub-mailboxes
# remove all message from it & its sub-mailboxes
# returns fast after destroying mailbox & sub-mailboxes
# in the background, proceeds to remove messages
#
# Returns a {Promise} for mailbox destroyed completion
Mailbox::destroyAndRemoveAllMessages = ->

    destroyBox = (box) -> box.destroyPromised()
    destroyMessages = (box) -> Message.safeRemoveAllFromBox box.id

    @getChildren()
    .then (children) =>
        mailboxesDestroyed = destroyBox this
        .then -> Promise.serie children, destroyBox

        # remove messages in the background (wont change the interface)
        mailboxesDestroyed
        .then => destroyMessages this
        .then -> Promise.serie children, destroyMessages
        .catch (err) ->
            log.error "Fail to remove messages from box", err.stack or err

        # returns fastly success or error for mailboxDestruction
        return mailboxesDestroyed


require './mailbox_imap'
require('bluebird').promisifyAll Mailbox, suffix: 'Promised'
require('bluebird').promisifyAll Mailbox::, suffix: 'Promised'




