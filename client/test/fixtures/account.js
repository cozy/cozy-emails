"use strict";

const getUID = require('../utils/guid').getUID;
const getName = require('../utils/guid').getName;

const MailboxFlags = require('../../app/constants/app_constants').MailboxFlags;
const MailboxSpecial = require('../../app/constants/app_constants').MailboxSpecial;
const MessageFilter = require('../../app/constants/app_constants').MessageFilter;
const FlagsConstants = require('../../app/constants/app_constants').FlagsConstants;
const MessageFlags = require('../../app/constants/app_constants').MessageFlags;

const inboxLabel = 'Boite principale';

module.exports.createMailbox = function Mailbox() {
  return {
    label: getName('mailbox'),
    id: getUID(),
    lastSync: new Date(),

    attribs: undefined,
    tree: undefined,

    nbFlagged: 117,
    nbRecent: 0,
    nbTotal: 3351,
    nbUnread: 164,
  }
};


module.exports.createInboxMailbox = function Inbox() {
  const mailboxLabel = 'Tous mes messages';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: inboxLabel,
    attribs: [MailboxFlags.ALL],
    tree: [inboxLabel],
  });
};


module.exports.createAllMailbox = function AllMailbox() {
  const mailboxLabel = 'Tous mes messages';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: mailboxLabel,
    attribs: [MailboxFlags.ALL],
    tree: [mailboxLabel],
  });
};


module.exports.createDraftMailbox = function DraftMailbox() {
  const mailboxLabel = 'Mes brouillons';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: mailboxLabel,
    attribs: [MailboxFlags.DRAFT],
    tree: [mailboxLabel],
  });
};


module.exports.createSentMailbox = function SentMailbox() {
  const mailboxLabel = 'Mes messages envoyés';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: mailboxLabel,
    attribs: [MailboxFlags.SENT],
    tree: [mailboxLabel],
  });
};


module.exports.createTrashMailbox = function TrashMailbox() {
  const mailboxLabel = 'Poubelle';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: mailboxLabel,
    attribs: [MailboxFlags.TRASH],
    tree: [mailboxLabel],
  });
};


module.exports.createJunkMailbox = function JunkMailbox() {
  const mailboxLabel = 'Mes messages non désirés';
  let mailbox = new module.exports.createMailbox();

  return Object.assign(mailbox, {
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
    label: mailboxLabel,
    attribs: [MailboxFlags.INBOX, MailboxFlags.FLAGGED],
    tree: [inboxLabel, mailboxLabel],
    nbTotal: mailbox.nbFlagged,
    nbUnread: 30,
  });
};

module.exports.createAccount = function Account() {

  const inboxMailbox = new module.exports.createInboxMailbox();
  const draftMailbox = new module.exports.createDraftMailbox();
  const junkMailbox = new module.exports.createJunkMailbox();
  const sentMailbox = new module.exports.createSentMailbox();
  const trashMailbox = new module.exports.createTrashMailbox();
  const unreadMailbox = new module.exports.createUnreadMailbox();
  const flaggedMailbox = new module.exports.createFlaggedMailbox();

  let mailboxes = [];
  mailboxes.push(inboxMailbox);
  mailboxes.push(draftMailbox);
  mailboxes.push(junkMailbox);
  mailboxes.push(sentMailbox);
  mailboxes.push(trashMailbox);
  mailboxes.push(unreadMailbox);
  mailboxes.push(flaggedMailbox);

  // Add mailbox created by user
  let counter = Math.round(Math.random() * 6);
  while (counter > 0) {
    mailboxes.push(new module.exports.createMailbox());
    --counter;
  }

  return {
    id: getUID(),

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

    mailboxes,

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
