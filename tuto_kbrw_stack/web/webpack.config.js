module.exports = {
    entry: './js/script.js',
    output: { filename: 'bundle.js' },
    plugins: [],
    module: {
        rules: [
            {
                test: /.js?$/,
                loader: 'babel-loader',
                exclude: /node_modules/,
                query: {
                    presets: ['es2015', 'react',
                        [
                            'jsxz',
                            {
                                dir: 'webflow'
                            }
                        ]],
                }
            }
        ]
    },
}