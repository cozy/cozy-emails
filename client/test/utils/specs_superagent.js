_ = require('lodash');
const SpecsUseragent = function SpecsUseragent() { };


SpecsUseragent.prototype.field = function fieldRequest(key, value) {
  this._request[key] = value;
  return this;
};


SpecsUseragent.prototype.attach = function fieldRequest(name, file) {
  this._attachements[name] = file;
  return this;
};


SpecsUseragent.prototype.put = function putRequest(uri) {
  this._request = { uri };
  return this;
};


SpecsUseragent.prototype.set = function setRequest() {
  this._request.headers = _.values(arguments);
  return this;
};


SpecsUseragent.prototype.send = function sendRequest(data) {
  this._request.query = _.transform(data, (result, value, key) => {
    result.push(`${key}=${value}`);
  }, []);
  return this;
};


SpecsUseragent.prototype.end = function endRequest(callback) {
  callback.call(this, null, { ok: true, body: this._request.body });
  return this;
};


SpecsUseragent.prototype.use = function useRequest(plugin) {
  return this;
};


SpecsUseragent.prototype.get = function getRequest() {
  return this;
};


SpecsUseragent.prototype.post = function postRequest(type) {
  this._request = { type };
  return this;
};


SpecsUseragent.prototype.del = function delRequest() {
  return this;
};


module.exports = new SpecsUseragent();
