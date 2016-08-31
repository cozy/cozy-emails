'use strict';

const random = require('./pseudorandom');


module.exports.getUID = function GUID() {
  function s4() {
    return Math.floor((1 + random()) * 0x10000)
      .toString(16)
      .substring(1);
  }
  // eslint-disable-next-line prefer-template
  return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
    s4() + '-' + s4() + s4() + s4();
};


module.exports.getName = function Name(prefix) {
  const length = 20;
  const alphanumeric = 'abcdefghijklmnopqrstuvwxyz';

  const value = [];
  if (prefix !== undefined) value.push(prefix, '-');
  while (value.length < length) {
    const index = Math.floor(random() * alphanumeric.length);
    value.push(alphanumeric[index]);
  }
  return value.join('');
};
