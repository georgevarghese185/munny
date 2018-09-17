const path = require('path');

module.exports = {
  entry: './build/scripts/index.test.js',
  output: {
    filename: 'index.js',
    path: path.resolve(__dirname, '../../dist')
  },
  watch: true,
  devServer: {
    contentBase: "./dist"
  },
  mode: "development"
};