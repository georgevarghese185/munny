const UI = require("src/plugins/home/ui")

exports.startUi = function() {
  return UI.start();
}

exports.setStateListener = function(stateListener) {
  UI.setStateListener(stateListener);
}
