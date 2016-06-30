// TODO: ajouter des méthodes pour générer X comptes dynamiquement
// TODO: ajouter des méthodes pour générer X messages dynamiquement
// TODO: commencer par ajouter des comptes statiques

/*
fixtures.emptyAccount
fixtures.account1
fixtures.account2
fixtures.account3

*/
"use strict";

const MailboxFlags = require('../../app/constants/app_constants').MailboxFlags;
const MailboxSpecial = require('../../app/constants/app_constants').MailboxSpecial;
const MessageFilter = require('../../app/constants/app_constants').MessageFilter;
const FlagsConstants = require('../../app/constants/app_constants').FlagsConstants;
const MessageFlags = require('../../app/constants/app_constants').MessageFlags;


const inboxLabel = 'Boite principale';

module.exports.createMailbox = function Inbox() {
  return {
    label: inboxLabel,
    id: "0",
    lastSync: new Date(),

    attribs: [MailboxFlags.INBOX],
    tree: [inboxLabel],

    nbFlagged: 117,
    nbRecent: 0,
    nbTotal: 3351,
    nbUnread: 164,
  }
};


module.exports.createAllMailbox = function AllMailbox() {
  const mailboxLabel = 'Tous mes messages';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    id: "1",
    label: mailboxLabel,
    attribs: [MailboxFlags.ALL],
    tree: [mailboxLabel],
  });
};


module.exports.createDraftMailbox = function DraftMailbox() {
  const mailboxLabel = 'Mes brouillons';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    id: "2",
    label: mailboxLabel,
    attribs: [MailboxFlags.DRAFT],
    tree: [mailboxLabel],
  });
};


module.exports.createSentMailbox = function SentMailbox() {
  const mailboxLabel = 'Mes messages envoyés';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    id: "3",
    label: mailboxLabel,
    attribs: [MailboxFlags.SENT],
    tree: [mailboxLabel],
  });
};


module.exports.createTrashMailbox = function TrashMailbox() {
  const mailboxLabel = 'Poubelle';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    id: "4",
    label: mailboxLabel,
    attribs: [MailboxFlags.TRASH],
    tree: [mailboxLabel],
  });
};


module.exports.createJunkMailbox = function JunkMailbox() {
  const mailboxLabel = 'Mes messages non désirés';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    id: "5",
    label: mailboxLabel,
    attribs: [MailboxFlags.INBOX, MailboxFlags.SPAM],
    tree: [mailboxLabel],
    nbTotal: 10,
    nbUnread: 3,
    nbFlagged: 3,
  });
};


module.exports.createUnreadMailbox = function UnreadMailbox() {
  const mailboxLabel = 'Mes messages non lu';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    id: "6",
    label: mailboxLabel,
    attribs: [MailboxFlags.INBOX, FlagsConstants.UNSEEN],
    tree: [inboxLabel, mailboxLabel],
    nbTotal: mailbox.nbUnread,
    nbFlagged: 30, // Messages nons lus ET flaggés
  });
};

module.exports.createFlaggedMailbox = function FlaggedMailbox() {
  const mailboxLabel = 'Mon courrier important';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    id: "7",
    label: mailboxLabel,
    attribs: [MailboxFlags.INBOX, MailboxFlags.FLAGGED],
    tree: [inboxLabel, mailboxLabel],
    nbTotal: mailbox.nbFlagged,
    nbUnread: 30,
  });
};


module.exports.createAccount = function Account() {
  const inboxMailbox = new module.exports.createMailbox();
  const draftMailbox = new module.exports.createDraftMailbox();
  const junkMailbox = new module.exports.createJunkMailbox();
  const sentMailbox = new module.exports.createSentMailbox();
  const trashMailbox = new module.exports.createTrashMailbox();
  const unreadMailbox = new module.exports.createUnreadMailbox();
  const flaggedMailbox = new module.exports.createFlaggedMailbox()

  return {
    id: '0d73a98a97651572eeb6e00c41f5817a',

    docType: 'account',
    initialized: true,
    patchIgnored: true,
    supportRFC4551: true,

    inboxMailbox: inboxMailbox.id,
    draftMailbox: draftMailbox.id,
    junkMailbox: junkMailbox.id,
    sentMailbox: sentMailbox.id,
    trashMailbox: trashMailbox.id,
    unreadMailbox: unreadMailbox.id,

    // TODO: faire des mailbox sans attribs
    //  pour gérer le cas
    mailboxes: [inboxMailbox, draftMailbox, junkMailbox, sentMailbox, trashMailbox, unreadMailbox, flaggedMailbox],

    // favorites: Array[4],

    label: 'noelie@cozycloud.cc',
    login: 'noelie@cozycloud.cc',
    name: 'noelie',
    password: 'xxxx',

    imapLogin: 'noelie@cozycloud.cc',
    imapPort: 993,
    imapSSL: true,
    imapServer: 'SSL0.OVH.NET',
    imapTLS: false,

    smtpPassword: 'xxxx',
    smtpLogin: 'noelie@cozycloud.cc',
    smtpPort: 465,
    smtpSSL: true,
    smtpServer: 'SSL0.OVH.NET',
    smtpTLS: false,
  }

};


module.exports.createGmailAccount = function Account() {
  let account = new module.exports.createAccount();

  // TODO: add [Gmail] mailbox:
  // - account.mailboxes.get('[Gmail]').attribs = [\Noselect]
  // - account.mailboxes.get('[Gmail]').tree = undefined

  // TODO: add INBOX mailbox
  // - account.mailboxes.get('inbox').attribs = [\Inbox]
  // - account.mailboxes.get('inbox').tree = undefined

  // TODO: change mailbox attribs and tree

  // return Object.assign(account, {
  //     attribs: [MailboxFlags.DRAFT],
  //     tree: [MailboxSpecial.draftMailbox],
  // });
}


module.exports.createOVHAccount = function Account() {
  let account = new module.exports.createAccount();

  // TODO: add twice INBOX mailbox
  // with different ID
  // return Object.assign(account, {
  //     attribs: [MailboxFlags.DRAFT],
  //     tree: [MailboxSpecial.draftMailbox],
  // });
}
// {
//   account1: {
//     id: '123',
//     label: 'personal',
//     mailboxes: [
//       { id: 'a1', label: 'inbox', accountID: '123' },
//       { id: 'a2', label: 'sent', accountID: '123' },
//     ],
//   },
//   account2: {
//     id: '124',
//     label: 'pro',
//     mailboxes: [
//       {
//         id: 'b1', label: 'mailbox', accountID: '124',
//       },
//       {
//         id: 'b2', label: 'folder1', accountID: '124',
//       },
//     ],
//   },
//   account3: {
//     id: '125',
//   },
//   emptyAccount: {
//     label: '',
//     login: '',
//     password: '',
//     imapServer: '',
//     imapLogin: '',
//     smtpServer: '',
//     id: null,
//     smtpPort: 465,
//     smtpSSL: true,
//     smtpTLS: false,
//     smtpMethod: 'PLAIN',
//     imapPort: 993,
//     imapSSL: true,
//     imapTLS: false,
//     accountType: 'IMAP',
//     favoriteMailboxes: null,
//   },
// };
