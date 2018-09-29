exports.waitForPluginReady = function (callback) {
  window.PLUGINS.pluginReady = callback
};

exports.setPluginsObjectImpl = function (obj) {
  window.PLUGINS = obj
};

exports.pluginReadyImpl = function (pluginName, startFn) {
  window.PLUGINS.pluginReady(pluginName, startFn);
};
