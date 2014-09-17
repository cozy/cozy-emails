require = patchRequire global.require
init = require("common").init
files = [
    {
        name: "file1.txt"
        size: 1234
        type: "text/plain"
    }
]
casper.test.begin 'Test file picker', 9, (test) ->
    init casper
    casper.start "http://localhost:9125/test", ->
        casper.evaluate ->
            window.__tests = {}
            FilePicker = require "components/file-picker"
            window.__tests.fp = React.renderComponent new FilePicker({editable: true}), document.body
        test.assertExists "input[type=file]", "File selector is visible"
        test.assertVisible ".dropzone", "Drop zone is visible"

    casper.then ->
        casper.evaluate ->
            window.__tests.rendered = false
            window.__tests.fp.setProps({editable: false}, -> window.__tests.rendered = true)
        casper.waitFor ->
            return casper.evaluate -> return window.__tests.rendered
        , ->
            test.assertNot(casper.exists("input[type=file]"), "File selector is not visible")
            test.assertNotVisible ".dropzone", "Drop zone is not visible"

    casper.then ->
        casper.evaluate (files) ->
            window.__tests.rendered = false
            window.__tests.fp.setProps({editable: false, files: files}, -> window.__tests.rendered = true)
        , {files: files}
        casper.waitFor ->
            return casper.evaluate -> return window.__tests.rendered
        , ->
            test.assertElementCount '.file-item', 1, "File is displayed"
            test.assertSelectorHasText '.file-name', 'file1.txt', "File name displayed"
            test.assertExists '.mime.fa-file-text-o', "MIME type"
            test.assertSelectorHasText '.file-detail', "1.23", "File size"
            test.assertNot(casper.exists(".file-item .delete"), "We can't delete files")


    casper.run ->
        test.done()

