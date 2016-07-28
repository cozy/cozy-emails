/* eslint indent: [2, 4] */

var path = require('path');

var webpack = require('webpack');

var ExtractTextPlugin = require('extract-text-webpack-plugin');
var CopyPlugin        = require('copy-webpack-plugin');
var AssetsPlugin      = require('assets-webpack-plugin');
var BrowserSyncPlugin = require('browser-sync-webpack-plugin');

// use the `OPTIMIZE` env VAR to switch from dev to production build
var optimize = process.env.OPTIMIZE === 'true';

/**
 * Loaders used by webpack
 *
 * - CSS and images files from `vendor` are excluded
 * - stylesheets are optimized via cssnano, minus svgo and autoprefixer that are
 * customized via PostCSS
 * - images are cache-busted in production build
 */
var cssOptions = optimize? 'css?-svgo&-autoprefixer!postcss':'css';
var imgPath = 'img/' + '[name]' + (optimize? '.[hash]': '') + '.[ext]';
var loaders = [
    {
        test: /\.js$/,
        loader: 'babel',
        exclude: /node_modules(?!\/superagent-throttle)/,
        query: {
            presets: ['es2015']
        }
    },
    {
        test: /\.coffee$/,
        loader: 'coffee'
    },
    {
        test: /\.styl$/,
        loader: ExtractTextPlugin.extract('style', cssOptions + '!stylus')
    },
    {
        test: /\.css$/,
        loader: ExtractTextPlugin.extract('style', cssOptions)
    },
    {
        test: /\.cjsx$/,
        loader: 'coffee-jsx'
    },
    {
        test: /\.json$/,
        loader: 'json'
    },
    {
        test: /\.(png|gif|jpe?g|svg)$/i,
        exclude: /vendor/,
        loader: 'file?name=' + imgPath
    },
    {
        test: /\.(ttf|eot|woff|woff2)$/i,
        loader: 'file?name=fonts/[name].[ext]'
    }
];

/**
 * Configure Webpack's plugins to tweaks outputs:
 *
 * all builds:
 * - ExtractTextPlugin: output CSS to file instead of inlining it
 * - CommonsChunkPlugin: push to _main_ file the common dependencies
 * - CopyPlugin: copy assets to public dir
 *
 * prod build:
 * - AssetsPlugin: paths to cache-busted's assets to read them from server
 * - DedupePlugin
 * - OccurenceOrderPlugin
 * - UglifyJsPlugin
 * - DefinePlugin: disable webpack env dev vars
 *
 * dev build:
 * - BrowserSyncPlugin: make hot reload via browsersync exposed at
 *   http://localhost:3000, proxified to the server app port
 */
var plugins = [
    new ExtractTextPlugin(optimize? 'app.[hash].css' : 'app.css'),
    new webpack.optimize.CommonsChunkPlugin({
        name:      'main',
        children:  true,
        minChunks: 2
    }),
    new CopyPlugin([
        { from: 'vendor/assets' },
        { from: 'vendor/datePicker/assets/' }
    ])
];

if (optimize) {
    plugins = plugins.concat([
        new AssetsPlugin({
            filename: '../build/webpack-assets.json'
        }),
        new webpack.optimize.DedupePlugin(),
        new webpack.optimize.OccurenceOrderPlugin(),
        new webpack.optimize.UglifyJsPlugin({
            mangle: true,
            compress: {
                warnings: false
            },
        }),
        new webpack.DefinePlugin({
            __SERVER__:      !optimize,
            __DEVELOPMENT__: !optimize,
            __DEVTOOLS__:    !optimize
        })
    ]);
} else {
    plugins = plugins.concat([
        new BrowserSyncPlugin({
            proxy: 'http://localhost:' + (process.env.PORT || 9125) + '/',
            open: false,
            ws: true
        })
    ]);
}

/**
 * PostCSS Config
 *
 * - autoprefixer to add vendor prefixes for last 2 versions
 * - mqpacker to bring together all MQ rule's set
 */
var postcss = [
    require('autoprefixer')(['last 2 versions']),
    require('css-mqpacker')
];

/**
 * Webpack config
 *
 * - output to `public` dir
 * - cache-bust assets when build for production
 */

module.exports = {
    entry: './app/initialize',
    output: {
        path: path.join(optimize? '../build/client' : '', 'public'),
        filename: optimize? 'app.[hash].js' : 'app.js',
        chunkFilename: optimize? 'register.[hash].js' : 'register.js'
    },
    resolve: {
        extensions: ['', '.js', '.coffee', '.cjsx', '.json']
    },
    debug: !optimize,
    devtool: 'source-map',
    module: {
        loaders: loaders
    },
    plugins: plugins,
    postcss: postcss
};
