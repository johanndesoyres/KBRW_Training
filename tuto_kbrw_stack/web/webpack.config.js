const MiniCssExtractPlugin = require('mini-css-extract-plugin');
//var ExtractTextPlugin = require('extract-text-webpack-plugin')
var path = require('path')
var webpack = require('webpack');

/*module.exports = {
    entry: './app.js',
    //...
    //This will output our files inside the ../priv/static directory
    output: {
        path: path.resolve(__dirname, '../priv/static'),
        filename: 'bundle.js'
    },
    //...
    //This will bundle all our .css file inside styles.css
    plugins: [new MiniCssExtractPlugin({
        filename: "styles.css"
    })],
    module: {
        rules: [
            {
                test: /.js?$/,
                loader: 'babel-loader',
                exclude: /node_modules/,
                options: {
                    presets: ['es2015', 'react',
                        [
                            'jsxz',
                            {
                                dir: 'webflow'
                            }
                        ]],
                    plugins: ["transform-object-rest-spread"],
                }
            },
            //...
            //Add to our loaders
            //This will process the .css files included in our application (app.js)
            {
                test: /\.css$/,
                use: [MiniCssExtractPlugin.loader, 'css-loader']
            }
        ]
    },
}*/


var client_config = {
    devtool: 'source-map',
    //>>> entry: './app.js',
    entry: "reaxt/client_entry_addition",
    //>>> output: { filename: 'bundle.js' , path: path.join(__dirname, '../priv/static' ) }, 
    output: {
        filename: 'client.[hash].js',
        path: path.join(__dirname, '../priv/static'),
        publicPath: '/public/'
    },
    plugins: [
        new MiniCssExtractPlugin({ filename: "styles.css" }), new webpack.IgnorePlugin(/vertx/)
    ],
    module: {
        loaders: [
            {
                test: /.js?$/,
                loader: 'babel-loader',
                exclude: /node_modules/,
                query: {
                    presets: ['es2015', 'stage-0', 'react',
                        // presets: ['es2015','stage-1', 'react',
                        [
                            'jsxz',
                            {
                                dir: 'webflow'
                            }
                        ]]
                }
            },
            {
                test: /\.css$/,
                use: [MiniCssExtractPlugin.loader, "css-loader"]
            }
        ]
    },
}


var server_config = Object.assign(Object.assign({}, client_config), {
    target: "node",
    entry: "reaxt/react_server",
    output: {
        path: path.join(__dirname, '../priv/react_servers'), //typical output on the default directory served by Plug.Static
        filename: 'server.js' //dynamic name for long term caching, or code splitting, use WebPack.file_of(:main) to get it
    },
})


module.exports = [client_config, server_config]



