americano = require 'americano-cozy'
Promise = require 'bluebird'
_ = require 'lodash'

# Public: Mailbox
# a {JugglingDBModel} for a mailbox (imap folder)
class Mailbox # make biscotto happy

module.exports = Mailbox = americano.getModel 'Mailbox',
    accountID: String        # Parent account
    label: String            # Human readable label
    path: String             # IMAP path
    tree: (x) -> x           # Normalized path as Array
    delimiter: String        # delimiter between this box and its children
    uidvalidity: Number      # Imap UIDValidity
    persistentUIDs: Boolean  # Imap persistentUIDs
    attribs: (x) -> x        # [String] Attributes of this folder
    children: (x) -> x       # [BLAMEJDB] children should not be saved

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

# Public: build a tree of the mailboxes
#
# accountID - id of the account
# mapper - if provided, it will be applied to each box
#
# Returns a {Promise} for the tree
Mailbox.getTree = (accountID, mapper = null) ->

    out = []
    byPath = {}
    DELIMITER = '/|/'

    transform = (boxData) ->
        box = new Mailbox boxData
        box.children = []
        return if mapper then mapper box
        else box

    Mailbox.rawRequestPromised 'treeMap',
        startkey: [accountID]
        endkey: [accountID, {}]
        include_docs: true

    .each (row) ->
        path = row.key[1..] # remove accountID

        # we keep a reference by path to easily find parent
        box = byPath[path.join DELIMITER] = transform row.doc

        if path.length is 1 # first level box
            out.push box
        else
            # this is a submailbox,  we find its parent
            # by path and append it
            parentPath = path[0..-2].join DELIMITER
            if byPath[parentPath]?
                byPath[parentPath].children.push box
            else
                log.error "NO MAILBOX of path #{parentPath} in #{accountID}"

    .return out

# Public: build a simpler version of the tree for client
# each node only have id, label and children fields
#
# accountID - id of the account
#
# Returns a {Promise} for the tree
Mailbox.getClientTree = (accountID) ->
    filter = (box) -> _.pick box, 'id', 'label', 'children', 'attribs'
    Mailbox.getTree accountID, filter



# Public: This function take the tree from node-imap
# and create appropriate boxes
#
# @TODO handle normalization of special folders
#
# accountID - id of the account
# tree - the raw boxes tree from {ImapPromisified::getBoxes}
#
# Returns a {Promise} for the {Account}'s specialUses attributes
Mailbox.createBoxesFromImapTree = (accountID, boxes) ->

    useRFC6154 = false
    specialUses = {}
    specialUsesGuess = {}
    Promise.serie boxes, (box) ->
        box.accountID = accountID

        # create box in data system (we need the id)
        Mailbox.createPromised box
        .then (jdbBox) ->
            if jdbBox.path is 'INBOX'
                specialUses['inboxMailbox'] = jdbBox.id
                return jdbBox

            # check if there is a RFC6154 attribute
            for field, attribute of Mailbox.RFC6154
                if attribute in jdbBox.attribs

                    # first RFC6154 attribute
                    unless useRFC6154
                        useRFC6154 = true

                    # add it to specialUses
                    specialUses[field] = jdbBox.id

            # do not attempt fuzzy match if the server uses RFC6154
            unless useRFC6154

                path = box.path.toLowerCase()
                if 0 is path.indexOf 'sent'
                    specialUsesGuess['sentMailbox'] = jdbBox.id
                else if 0 is path.indexOf 'draft'
                    specialUsesGuess['draftMailbox'] = jdbBox.id
                else if 0 is path.indexOf 'flagged'
                    specialUsesGuess['flaggedMailbox'] = jdbBox.id
                else if 0 is path.indexOf 'trash'
                    specialUsesGuess['trashMailbox'] = jdbBox.id
                # @TODO add more

            return jdbBox

    .then (boxes) ->
        # pick the default 4 favorites box
        favorites = []
        priorities = ['inbox', 'all', 'sent', 'draft']

        unless useRFC6154
            specialUses[key] = value for key, value of specialUsesGuess


        # see if we have some of the priorities box
        for type in priorities when id = specialUses[type + 'Mailbox']
            favorites.push id


        # we dont have our 4 favorites, pick at random
        for box in boxes when favorites.length < 4
            if box.id not in favorites and '\\NoSelect' not in box.attribs
                favorites.push box.id

        return favorites

    .then (favorites) ->
        specialUses.favorites = favorites
        return specialUses


# Public: destroy a mailbox
# remove all message from it
# returns fast after destroying mailbox
# in the background, proceeds to remove messages
#
# Returns a {Promise} for mailbox destroyed completion
Mailbox::destroyEverything = ->

    mailboxID = @id

    mailboxDestroyed = @destroyPromised()

    # do this in the background (wont change the interface)
    mailboxDestroyed.then -> Message.safeRemoveAllFromBox mailboxID
    .catch (err) -> log.error err

    # returns fastly success or error for mailboxDestruction
    return mailboxDestroyed



require('bluebird').promisifyAll Mailbox, suffix: 'Promised'
require('bluebird').promisifyAll Mailbox::, suffix: 'Promised'




