if global?
    require = patchRequire global.require
else
    require = patchRequire this.require
    require.globals.casper = casper
init = require(fs.workingDirectory + "/client/tests/casper/common").init
files = [
    {
        fileName: "file1.txt"
        generatedFileName: "file1.txt"
        length: 1234
        contentType: "text/plain"
        url: ''
    }
]
casper.test.begin 'Test file picker', 9, (test) ->
    init casper
    initFPTest = ->
        casper.evaluate ->
            window.__tests = {}
            window.cozyMails =
                log: ->
                    console.log JSON.stringify(Array.prototype.slice.call(arguments))
            FilePicker = require "components/file_picker"
            window.__tests.fp = React.renderComponent new FilePicker({editable: true}), document.body
    casper.start casper.cozy.startUrl + "test", ->
        initFPTest()
        test.assertExists "input[type=file]", "File selector is visible"
        test.assertVisible ".dropzone", "Drop zone is visible"

    casper.then ->
        initFPTest()
        casper.evaluate ->
            window.__tests.rendered = false
            window.__tests.fp.setProps({editable: false}, -> window.__tests.rendered = true)
        casper.waitFor ->
            return casper.evaluate -> return window.__tests.rendered
        , ->
            test.assertNot(casper.exists("input[type=file]"), "File selector is not visible")
            test.assertNotVisible ".dropzone", "Drop zone is not visible"

    casper.then ->
        initFPTest()
        casper.evaluate (files) ->
            files = files.map (file) ->
                # this is weird: Immutable.Map doesn't behave the same in PhantomJs and SlimmerJS
                maped = Immutable.Map file
                return maped.get(0) or maped
            files = Immutable.Vector.from files
            window.__tests.rendered = false
            window.__tests.fp.setProps({editable: false, value: files}, -> window.__tests.rendered = true)
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

