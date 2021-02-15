const MiniCssExtractPlugin = require('mini-css-extract-plugin');
var path = require('path')

module.exports = {
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
}




