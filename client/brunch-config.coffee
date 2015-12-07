exports.config =
    files:
        javascripts:
            joinTo:
                'js/app.js': /^app/
                'js/vendor.js': /^vendor/
            order:
                before: [
                    'vendor/scripts/underscore.js'
                    'vendor/scripts/jquery.js'
                ]
                after: ['vendor/plugins/**/*.js']

        stylesheets:
            joinTo: 'css/app.css'
            order:
                after: ['vendor/plugins/**/*.css']

    plugins:
        postcss:
            processors: [
                require('autoprefixer')(['last 2 versions'])
            ]


    overrides:
        production:
            paths:
                public: '../build/client/public'

            plugins:
                postcss:
                    processors: [
                        require('autoprefixer')(['last 2 versions'])
                        require('css-mqpacker')
                        require('csswring')
                    ]
