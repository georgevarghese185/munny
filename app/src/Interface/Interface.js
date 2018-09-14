exports._setupInterface = function() {

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

      return window.__Native_Interface[key].apply(window.__Native_Interface, newArgs);
    }
  })
}

exports._spawnWebScripter = function(id, callback) {
  Interface.spawnWebScripter(id, callback)
}

exports._killScripter = function(id) {
  Interface.killScripter(id);
}

exports._executeScripter = function(id, script, success, error) {
  var success1 = function() {
    console.log(arguments);
    success(arguments[0]);
  }
  Interface.executeScripter(id, script, success1, error)
}

exports._cancelScripter = function (id) {
  Interface.cancelScripter(id);
};

exports._showScripter = function(id) {
  Interface.showScripter(id);
}

exports._hideScripter = function (id) {
  Interface.hideScripter(id);
};

exports._exit = function () {
  Interface.exit();
};
