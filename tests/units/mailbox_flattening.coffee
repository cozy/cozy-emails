mailutils = require '../../server/utils/jwz_tools'
should = require('should')


describe 'mailutils.flattenMailboxTree various kind of tree', ->

    it 'flatten "normal" tree', ->

        boxes = mailutils.flattenMailboxTree ARBO1
        boxes.should.have.lengthOf 6
        boxes[0].should.have.property 'path', 'INBOX.Sent'
        boxes[0].should.have.property('tree').with.lengthOf 2


    it 'flatten "Gmail>OVH" tree', ->

        boxes = mailutils.flattenMailboxTree ARBO2
        boxes.should.have.lengthOf 15
        boxes[1].should.have.property 'path', 'INBOX.perso'
        # the root INBOX is discarded
        boxes[1].should.have.property 'label', 'perso'
        boxes[1].should.have.property('tree').with.lengthOf 1
        boxes[3].should.have.property 'path', 'INBOX.[Gmail].Important'

    it 'flatten "Gmail" tree', ->

        boxes = mailutils.flattenMailboxTree ARBO3
        boxes.should.have.lengthOf 11



ARBO1 =
    INBOX:
        attribs: [ '\\HasChildren' ]
        delimiter: '.'
        children:
            Sent:
                attribs: [ '\\HasNoChildren' ]
                delimiter: '.'
                children: null

        parent: null
    Trash:
        attribs: [ '\\HasNoChildren' ]
        delimiter: '.'
        children: null
        parent: null
    Drafts:
        attribs: [ '\\HasNoChildren' ]
        delimiter: '.'
        children: null
        parent: null
    Sent:
        attribs: [ '\\HasNoChildren' ]
        delimiter: '.'
        children: null
        parent: null
    Spam:
        attribs: [ '\\HasNoChildren' ]
        delimiter: '.'
        children: null
        parent: null



ARBO2 = INBOX:
     attribs: [ '\\HasChildren' ]
     delimiter: '.'
     children:
        perso:
           attribs: [ '\\HasNoChildren' ]
           delimiter: '.'
           children: null
        '[Gmail]':
           children:
              Spam:
                 attribs: []
                 delimiter: '.'
                 children: null
              Important:
                 attribs: []
                 delimiter: '.'
                 children: null
              'Tous les messages':
                 attribs: []
                 delimiter: '.'
                 children: null
        INBOX:
           children:
              Sent:
                 attribs: []
                 delimiter: '.'
                 children: null
              Drafts:
                 attribs: []
                 delimiter: '.'
                 children: null
              Junk:
                 attribs: []
                 delimiter: '.'
                 children: null
              Trash:
                 attribs: []
                 delimiter: '.'
                 children: null
        'Box 1':
           attribs: [ '\\HasNoChildren' ]
           delimiter: '.'
           children: null
        Brouillons:
           attribs: [ '\\HasNoChildren' ]
           delimiter: '.'
           children: null
        Sent:
           attribs: [ '\\HasNoChildren' ]
           delimiter: '.'
           children: null
        test:
           attribs: [ '\\HasNoChildren' ]
           delimiter: '.'
           children: null
     parent: null

ARBO3 =
    INBOX:
        attribs: [ '\\HasNoChildren' ]
        delimiter: '/'
        children: null
        parent: null
    Professionnel:
        attribs: [ '\\HasNoChildren' ]
        delimiter: '/'
        children: null
        parent: null
    'Reçus':
        attribs: [ '\\HasNoChildren' ]
        delimiter: '/'
        children: null
        parent: null
    '[Gmail]':
        attribs: [ '\\Noselect',  '\\HasChildren' ]
        delimiter: '/'
        children:
            Brouillons:
                attribs: [ '\\HasNoChildren',  '\\Drafts' ]
                delimiter: '/'
                children: null
                special_use_attrib: '\\Drafts'
            Corbeille:
                attribs: [ '\\HasNoChildren',  '\\Trash' ]
                delimiter: '/'
                children: null
                special_use_attrib: '\\Trash'
            Important:
                attribs: [ '\\HasNoChildren',  '\\Important' ]
                delimiter: '/'
                children: null
            'Messages envoyés':
                attribs: [ '\\HasNoChildren',  '\\Sent' ]
                delimiter: '/'
                children: null
                special_use_attrib: '\\Sent'
            Spam:
                attribs: [ '\\HasNoChildren',  '\\Junk' ]
                delimiter: '/'
                children: null
                special_use_attrib: '\\Junk'
            Suivis:
                attribs: [ '\\HasNoChildren',  '\\Flagged' ]
                delimiter: '/'
                children: null
                special_use_attrib: '\\Flagged'
            'Tous les messages':
                attribs: [ '\\HasNoChildren',  '\\All' ]
                delimiter: '/'
                children: null
                special_use_attrib: '\\All'