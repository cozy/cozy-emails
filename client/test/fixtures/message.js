"use strict";

const _ = require('lodash');
const Immutable = require('immutable');

const MessageFlags = require('../../app/constants/app_constants').MessageFlags;

const getUID = require('../utils/guid').getUID;
const getName = require('../utils/guid').getName;

const AccountFixture = require('./account');


function createMailboxIDs (account) {
  const max = Math.round(Math.random() * account.mailboxes.length);
  const min = Math.round(Math.random() * max);
  const mailboxes = account.mailboxes.slice(min, max);

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

  return mailboxIDs;
}

module.exports.createMessage = function createMessage(data) {
  const account = AccountFixture.createAccount();
  const date = (data.date || new Date()).toISOString();

  return {
    id: `message-${getUID()}`,
    conversationID: `conversationID-${getUID()}`,

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
    // so as ../../app/getters/message.coffee
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
  return Object.assign(message, { flags: [MessageFlags.FLAGGED] });
}

module.exports.createDraft = function DraftMessage(data) {
  const message = module.exports.createMessage(data);
  return Object.assign(message, { flags: [MessageFlags.DRAFT] });
}

module.exports.createAttached = function AttachedMessage(data) {
  const message = module.exports.createMessage(data);
  return Object.assign(message, { attachments: [
    {id: `attachments-${getUID()}`, value: `../monFichier-${getUID()}.png` },
    {id: `attachments-${getUID()}`, value: `../monFichier-${getUID()}.png` },
  ] });
}
