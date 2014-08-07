path = require 'path'

exports.config =
    files:
        javascripts:
            joinTo:
                'js/app.js': /^app/
                'js/vendor.js': /^vendor|bower_components/
            order:
                # Files in `vendor` directories are compiled before other files
                # even if they aren't specified in order.
                before: [
                    'bower_components/react/react-with-addons.js'
                    'bower_components/jquery/dist/jquery.js'
                    'bower_components/underscore/underscore.js'
                    'bower_components/backbone/backbone.js'
                    'vendor/javascripts/superagent.js'
                    'vendor/javascripts/bootstrap-3.1.1.min.js'
                ]

        stylesheets:
            joinTo: 'css/app.css'
            order:
                before: []
                after: ['vendor/stylesheets/helpers.css']

    plugins:
        cleancss:
            keepSpecialComments: 0
            removeEmpty: true

        digest:
            referenceFiles: /\.jade$/

    overrides:
        production:
            # re-enable when uglifyjs will handle properly in source maps
            # with sourcesContent attribute
            #optimize: true
            sourceMaps: true
            paths:
                public: path.resolve __dirname, '../build/client/public'