Immutable = require 'immutable'

{MailboxFlags} = require '../../constants/app_constants'

module.exports = AccountTranslator =

    # Creates an immutable account from a raw account object
    toImmutable: (raw) ->

        # Used to sort mailboxes
        last = {}
        weight1 = 900
        weight2 = 400

        # Creates Immutable OrderedMap of mailboxes
        mailboxes = Immutable.Iterable raw.mailboxes
            .toKeyedSeq()
            .mapKeys (_, box) -> box.id
            .map (box) ->

                box.depth = box.tree.length - 1

                # fake weight for sort
                if box.depth is 0
                    label = box.label.toLowerCase()
                    if label is 'inbox'
                        box.weight = 1000
                    else if (box.attribs.length > 0 or
                            /draft/.test(label) or
                            /sent/.test(label) or
                            /trash/.test(label))
                        box.weight = weight1
                        weight1 -= 5
                    else
                        box.weight = weight2
                        weight2 -= 5
                    last[box.depth] = box.weight
                else
                    box.weight = last[box.depth - 1] - 0.1
                    last[box.depth] = box.weight

                return Immutable.Map box

            .toOrderedMap()

        delete raw.totalUnread

        raw.mailboxes = mailboxes
        return Immutable.Map raw
