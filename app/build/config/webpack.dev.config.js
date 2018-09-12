const path = require('path');

module.exports = {
  entry: './build/scripts/index.dev.js',
  output: {
    filename: 'index.js',
    path: path.resolve(__dirname, '../../dist')
  },
  devServer: {
    contentBase: "./dist"
  },
  mode: "development"
};
