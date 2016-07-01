"use strict";



module.exports.getUID = function GUID() {
  function s4() {
    return Math.floor((1 + Math.random()) * 0x10000)
      .toString(16)
      .substring(1);
  }
  return  s4() + s4() + '-' + s4() + '-' + s4() + '-' +
    s4() + '-' + s4() + s4() + s4();
}


module.exports.getName = function Name() {
  let prefix = arguments[0] || '';

  let length = 20;
  const alphanumeric = 'abcdefghijklmnopqrstuvwxyz';

  let value = [];
  if (arguments[0] != undefined) value.push(arguments[0], '-');
  while (value.length < length) {
    let index = Math.floor(Math.random() * alphanumeric.length)
    value.push(alphanumeric[index]);
  }
  return value.join('');
}
