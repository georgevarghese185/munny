exports.setupInterface = function() {

  window.InterfaceCallbacks = {}
  callbackId = 0;
  var mapCallback = function(fn) {
    const id = callbackId;
    window.InterfaceCallbacks[id.toString()] = function() {
      delete window.InterfaceCallbacks[id.toString()];
      fn.apply(window, arguments);
    }

    return (callbackId++).toString();
  }

  window.Interface = {};
  Object.keys(window.__Native_Interface).map(function(key) {
    window.Interface[key] = function() {
      var newArgs = Array.from(arguments).map(function(arg) {
        if(typeof arg === "function") {
          return mapCallback(arg);
        } else {
          return arg;
        }
      })

      window.__Native_Interface[key].apply(window.__Native_Interface, newArgs);
    }
  })
}

exports.spawnWebScripter = function(id, callback) {
  Interface.spawnWebScripter(id, callback)
}

exports.killScripter = function(id) {
  Interface.killScripter(id);
}

exports.executeScripter = function(id, script, success, error) {
  var success1 = function() {
    console.log(arguments);
    success(arguments[0]);
  }
  Interface.executeScripter(id, script, success1, error)
}

exports.showScripter = function(id) {
  Interface.showScripter(id);
}

exports.hideScripter = function (id) {
  Interface.hideScripter(id);
};

exports.exit = function () {
  Interface.exit();
};
