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
    uidvalidity: Number      # Imap UIDValidity
    persistentUIDs: Boolean  # Imap persistentUIDs
    attribs: (x) -> x        # [String] Attributes of this folder
    children: (x) -> x       # [BLAMEJDB] children should not be saved


# Return an array of selectable mailboxes for an accountID
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
            byPath[parentPath].children.push box

    .return out

# Public: build a simpler version of the tree for client
# each node only have id, label and children fields
# 
# accountID - id of the account
# 
# Returns a {Promise} for the tree
Mailbox.getClientTree = (accountID) ->
    filter = (box) -> _.pick box, 'id', 'label', 'children'
    Mailbox.getTree accountID, filter


IGNORE_ATTRIBUTES = ['\\HasNoChildren', '\\HasChildren']
# Public: This function take the tree from node-imap
# and create appropriate boxes
# 
# @TODO handle normalization of special folders
# 
# accountID - id of the account
# tree - the raw boxes tree from {ImapPromisified::getBoxes}
# 
# Returns a {Promise} for the {Account}'s specialUses attributes
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




