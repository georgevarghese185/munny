exports.spawnWebScripterImpl = function(id, callback) {
  Interface.spawnWebScripter(id, callback)
}

exports.killScripterImpl = function(id) {
  Interface.killScripter(id);
}

exports.executeScripterImpl = function(id, script, success, error) {
  var success1 = function() {
    console.log(arguments);
    success(arguments[0]);
  }
  Interface.executeScripter(id, script, success1, error)
}

exports.cancelScripterImpl = function (id) {
  Interface.cancelScripter(id);
};

exports.showScripterImpl = function(id) {
  Interface.showScripter(id);
}

exports.hideScripterImpl = function (id) {
  Interface.hideScripter(id);
};
