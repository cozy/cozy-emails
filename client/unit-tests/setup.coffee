jsdom = require('jsdom')

global.window = jsdom.jsdom('<!doctype html><html><body></body></html>').defaultView
global.document = window.document
global.navigator = window.navigator
