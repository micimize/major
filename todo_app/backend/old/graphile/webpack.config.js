const path = require('path')
const webpack = require('webpack')
const TerserPlugin = require('terser-webpack-plugin')

const GRAPHIQL = false

module.exports = {
  context: path.resolve(__dirname),
  devtool: 'source-map',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'index.js',
    libraryTarget: 'commonjs'//2'
  },
  mode: 'development' || 'production',
  target: 'node',
  plugins: [
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': '"production"',
      'process.env.POSTGRAPHILE_ENV': '"production"',
      'process.env.NODE_PG_FORCE_NATIVE': JSON.stringify('1'),
      ...(GRAPHIQL ? null : { 'process.env.POSTGRAPHILE_OMIT_ASSETS': '"1"' }),
    }),
  ],
  node: {
    __dirname: false, // just output `__dirname`
  },
  optimization: {
    minimizer: [
      new TerserPlugin({
        terserOptions: {
          // Without this, you may get errors such as
          // `Error: GraphQL conflict for 'e' detected! Multiple versions of graphql exist in your node_modules?`
          mangle: false,
        },
      }),
    ],
  },

  externals: [
    // We cannot bundle native modules, so leave it out:
    'pg-native',

    // ref this comment:
    // https://github.com/websockets/ws/issues/1126#issuecomment-476246113
    'bufferutil',
    'utf-8-validate',

    // was giving me issues
    'semver',
  ],
}
