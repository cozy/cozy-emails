americano = require 'americano-cozy'
Promise = require 'bluebird'
_ = require 'lodash'

module.exports = Mailbox = americano.getModel 'Mailbox',
    accountID: String        # Parent account
    label: String            # Human readable label
    path: String             # IMAP path
    tree: (x) -> x           # Normalized path as Array
    uidvalidity: Number      # Imap UIDValidity
    persistentUIDs: Boolean  # Imap persistentUIDs
    attribs: (x) -> x        # [String] Attributes of this folder
    children: (x) -> x       # this should not be saved but juggling doesnt
                             # allow seting properties not in the model


# Return an array of selectable mailboxes for an accountID
Mailbox.getBoxes = (accountID) ->
    Mailbox.rawRequestPromised 'treeMap',
        startkey: [accountID]
        endkey: [accountID, {}]
        include_docs: true

    .map (row) -> new Mailbox row.doc
    .filter (box) -> '\\Noselect' not in box.attribs

# Returns the mailboxes tree for an accountID
# the filter, if provided will be applied to each box
Mailbox.getTree = (accountID, filter) ->

    out = []
    byPath = {}
    DELIMITER = '/|/'

    transform = (boxData) ->
        box = new Mailbox boxData
        box.children = []
        return if filter then filter box
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
            byPath[parentPath].children.push box

    .return out

# simpler version of the tree for client
Mailbox.getClientTree = (accountID) ->
    filter = (box) -> _.pick box, 'id', 'label', 'children'
    Mailbox.getTree accountID, filter


# This function take the tree from node-imap
# and create appropriate boxes
# @TODO handle normalization of special folders
# @TODO tentatively find special folders by name (Sent, SENT, ...)
IGNORE_ATTRIBUTES = ['\\HasNoChildren', '\\HasChildren']
Mailbox.createBoxesFromImapTree = (accountID, tree) ->
    boxes = []

    # recursively browse the imap box tree

    do handleLevel = (children = tree, pathStr = '', pathArr = []) ->
        for name, child of children
            subPathStr = pathStr + name + child.delimiter
            subPathArr = pathArr.concat name
            handleLevel child.children, subPathStr, subPathArr
            boxes.push
                accountID: accountID
                label: name
                path: pathStr + name
                tree: subPathArr
                attribs: _.difference child.attribs, IGNORE_ATTRIBUTES

    Promise.serie boxes, (box) ->
        Mailbox.createPromised box

require('bluebird').promisifyAll Mailbox, suffix: 'Promised'
require('bluebird').promisifyAll Mailbox::, suffix: 'Promised'




