var jade = require('pug-runtime'); module.exports = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
;var locals_for_with = (locals || {});(function (assets, imports) {
buf.push("<!DOCTYPE html><html><head><title>Cozy Emails</title><meta charset=\"utf-8\"><meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge,chrome=1\"><meta name=\"viewport\" content=\"width=device-width\"><link rel=\"stylesheet\"" + (jade.attr("href", "" + (assets? assets.css : 'app.css') + "", true, true)) + "><script>" + (null == (jade_interp = imports) ? "" : jade_interp) + "</script><script" + (jade.attr("src", "" + (assets? assets.js : 'app.js') + "", true, true)) + " defer></script></head><body></body></html>");}.call(this,"assets" in locals_for_with?locals_for_with.assets:typeof assets!=="undefined"?assets:undefined,"imports" in locals_for_with?locals_for_with.imports:typeof imports!=="undefined"?imports:undefined));;return buf.join("");
}