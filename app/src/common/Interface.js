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

      return window.__Native_Interface[key].apply(window.__Native_Interface, newArgs);
    }
  })
}

exports.exit = function () {
  Interface.exit();
};
