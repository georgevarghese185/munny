const UI = require('src/plugins/home/ui');

exports.startHomeScreenImpl = function(rootId, onEvent) {
  return UI.start(rootId, onEvent)
}
