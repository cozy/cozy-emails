'use strict';

const random = require('../utils/pseudorandom');
const getUID = require('../utils/guid').getUID;
const getName = require('../utils/guid').getName;

const Constants = require('../../app/constants/app_constants');
const MailboxFlags = Constants.MailboxFlags;
const FlagsConstants = Constants.FlagsConstants;

const inboxLabel = 'Boite principale';


module.exports.createMailbox = function Mailbox() {
  return {
    label: getName('mailbox'),
    id: `mailbox-${getUID()}`,
    lastSync: new Date(),

    attribs: undefined,
    tree: undefined,

    nbFlagged: 3,
    nbSent: 2,
    nbRecent: 0,
    nbTotal: 35,
    nbUnread: 4,
  };
};


module.exports.createInboxMailbox = function Inbox() {
  const mailbox = module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: inboxLabel,
    attribs: [MailboxFlags.INBOX],
    tree: [inboxLabel],
  });
};


module.exports.createAllMailbox = function AllMailbox() {
  const mailboxLabel = 'Tous mes messages';
  const mailbox = module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: mailboxLabel,
    attribs: [MailboxFlags.ALL],
    tree: [mailboxLabel],
  });
};


module.exports.createDraftMailbox = function DraftMailbox() {
  const mailboxLabel = 'Mes brouillons';
  const mailbox = module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: mailboxLabel,
    attribs: [MailboxFlags.DRAFT],
    tree: [mailboxLabel],
    nbTotal: 124,
  });
};


module.exports.createSentMailbox = function SentMailbox() {
  const mailboxLabel = 'Mes messages envoyés';
  const mailbox = module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: mailboxLabel,
    attribs: [MailboxFlags.SENT],
    tree: [mailboxLabel],
    nbFlagged: 2,
    nbTotal: 300,
    nbUnread: 0,
  });
};


module.exports.createTrashMailbox = function TrashMailbox() {
  const mailboxLabel = 'Poubelle';
  const mailbox = module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: mailboxLabel,
    attribs: [MailboxFlags.TRASH],
    tree: [mailboxLabel],
    nbFlagged: 76,
    nbTotal: 867,
    nbUnread: 40,
  });
};


module.exports.createJunkMailbox = function JunkMailbox() {
  const mailboxLabel = 'Mes messages non désirés';
  const mailbox = module.exports.createMailbox();

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
  const mailbox = module.exports.createMailbox();

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
  const mailbox = module.exports.createMailbox();

  return Object.assign(mailbox, {
    label: mailboxLabel,
    attribs: [MailboxFlags.INBOX, MailboxFlags.FLAGGED],
    tree: [inboxLabel, mailboxLabel],
    nbTotal: mailbox.nbFlagged,
    nbUnread: 30,
  });
};


module.exports.createAccount = function Account(options) {
  const inboxMailbox = module.exports.createInboxMailbox();
  const draftMailbox = module.exports.createDraftMailbox();
  const junkMailbox = module.exports.createJunkMailbox();
  const sentMailbox = module.exports.createSentMailbox();
  const trashMailbox = module.exports.createTrashMailbox();
  const unreadMailbox = module.exports.createUnreadMailbox();
  const flaggedMailbox = module.exports.createFlaggedMailbox();
  const allMailbox = module.exports.createAllMailbox();

  const mailboxes = [];
  mailboxes.push(allMailbox);
  mailboxes.push(inboxMailbox);
  mailboxes.push(draftMailbox);
  mailboxes.push(junkMailbox);
  mailboxes.push(sentMailbox);
  mailboxes.push(trashMailbox);
  mailboxes.push(unreadMailbox);
  mailboxes.push(flaggedMailbox);

  // Do not add random content in a fixture, how to test with random
  // number of values ?
  // Setting randomizeAdditionalMailboxes to true by default to preserve legacy
  // but additional mailboxes should be passed as a parameter.
  const randomizeAdditionalMailboxes = !options ||
    typeof options.randomizeAdditionalMailboxes === 'undefined' ||
      options.randomizeAdditionalMailboxes;

  if (randomizeAdditionalMailboxes) {
    // Add mailbox created by user
    let counter = Math.round(random() * 6);
    while (counter > 0) {
      mailboxes.push(module.exports.createMailbox());
      --counter;
    }
  }

  return {
    id: `account-${getUID()}`,

    docType: 'account',
    initialized: true,
    patchIgnored: true,
    supportRFC4551: true,

    inboxMailbox: inboxMailbox.id,
    flaggedMailbox: flaggedMailbox.id,
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
  };
};


module.exports.createGmailAccount = function Account() {
  // let account = module.exports.createAccount();

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
};


module.exports.createOVHAccount = function Account() {
  // let account = module.exports.createAccount();

  // TODO: add twice INBOX mailbox
  // with different ID
  // return Object.assign(account, {
  //     attribs: [MailboxFlags.DRAFT],
  //     tree: [MailboxSpecial.draftMailbox],
  // });
};
