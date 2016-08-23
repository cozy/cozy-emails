"use strict";

const _ = require('lodash');
const Immutable = require('immutable');

const MessageFlags = require('../../app/constants/app_constants').MessageFlags;

const random = require('../utils/pseudorandom');
const getUID = require('../utils/guid').getUID;
const getName = require('../utils/guid').getName;

const AccountFixture = require('./account');


module.exports.createMessage = function createMessage(data) {
  const account = data.account || AccountFixture.createAccount();
  const date = (data.date || new Date()).toISOString();

  return {
    id: `message-${getUID()}`,
    conversationID: data.conversationID || `conversationID-${getUID()}`,

    accountID: account.id,
    mailboxIDs: createMailboxIDs(account),

    normSubject: "[cozy/cozy-ui] Add mixed checkbox style (#19)",
    subject: "[cozy/cozy-ui] Add mixed checkbox style (#19)",
    priority: "normal",

    // updated: date,
    createdAt: date,
    date: date,

    html: "contenu de mon emails",
    text: "sqdd",

    // TODO: add some tests for these properties
    // but I dont understand what it is about?!?
    // hasTwin: [],
    // references: [],
    // headers: {},
    // ignoreInCount: false,

    // TODO: these tags should be tested
    // when compose feature will be implemented
    // so as ../../app/puregetters/message.coffee
    // that format messageStore for ReactComponent
    // to: [],
    // replyTo: [],
    // bcc: [],
    // cc: [],
    // inReplyTo: [],
    // from: [],
    attachments: data.attachments,

    flags: [MessageFlags.SEEN],

    // settings
    _displayImages: data.images
  }
}

module.exports.createUnread = function UnreadMessage(data) {
  const message = module.exports.createMessage(data);
  delete message.flags;
  return message;
}

module.exports.createFlagged = function FlaggedMessage(data) {
  const message = module.exports.createMessage(data);
  message.flags.push(MessageFlags.FLAGGED);
  return message;
}

module.exports.createDraft = function DraftMessage(data) {
  const message = module.exports.createMessage(data);
  message.flags.push(MessageFlags.DRAFT);
  return message;
}

module.exports.createTrash = function TrashMessage(data) {
  const message = module.exports.createMessage(data);

  if (data.account) {
    // Remove Inbox form mailboxIDs
    let mailboxIDs = _.omit(message.mailboxIDs, data.account.inboxMailbox);

    // Replace it by TrashMailbox
    const trashMailbox = data.account.mailboxes.find((mailbox) => {
      return data.account.trashMailbox  === mailbox.id;
    });
    mailboxIDs[data.account.trashMailbox] = trashMailbox.nbTotal;
    message.mailboxIDs = mailboxIDs;
  }
  return message;
}


module.exports.createAttached = function AttachedMessage(data) {
  const message = module.exports.createMessage(data);

  const flags = (message.flags || []).push(MessageFlags.ATTACH);
  message.flags = flags;

  return Object.assign(message, { attachments: [
    {id: `attachments-${getUID()}`, value: `../monFichier-${getUID()}.png` },
    {id: `attachments-${getUID()}`, value: `../monFichier-${getUID()}.png` },
  ] });
}


function createMailboxIDs (account) {
  const max = Math.round(random() * account.mailboxes.length);
  const min = Math.round(random() * max);
  const mailboxes = account.mailboxes.slice(min, max + 1);

  // Create MailboxIDs
  const mailboxIDs = _.transform(mailboxes, (result, mailbox) => {
    result[mailbox.id] = mailbox.nbTotal
  }, {})

  // inboxMailbox must be there
  if (undefined === mailboxIDs[account.inboxMailbox]) {
    const inbox = account.mailboxes.find((mailbox) => {
      return account.inboxMailbox === mailbox.id;
    });
    mailboxIDs[inbox.id] = inbox.nbTotal;
  }

  // MailboxID must contain more than 1 value
  // becauseof tests cases
  if (1 >= mailboxIDs.length) {
    const unreadMailbox = account.mailboxes.find((mailbox) => {
      return account.sentMailbox === mailbox.id;
    });
    mailboxIDs[unreadMailbox.id] = unreadMailbox.nbSent;
  }

  return mailboxIDs;
}
