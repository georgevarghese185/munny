const SettingsScreen = require('src/plugins/hdfc/ui');

exports.startSettingsScreenImpl = function (rootId, onEvent) {
  return SettingsScreen.start(rootId, onEvent)
};
