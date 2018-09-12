const path = require('path');

module.exports = {
  entry: './build/scripts/index.prod.js',
  output: {
    filename: 'index.js',
    path: path.resolve(__dirname, '../../dist')
  },
  mode: "production"
};
