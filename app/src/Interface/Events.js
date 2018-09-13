exports["setupEventsImpl"] = function(events) {
  window.InterfaceCallbacks.EventListeners = {};

  events.map(function(event) {
    window.InterfaceCallbacks.EventListeners[event] = [];
    window.InterfaceCallbacks[event] = function() {
      var args = arguments;
      window.InterfaceCallbacks.EventListeners[event].map(function(listener) {
        listener.apply(window, args);
      });
    }
  });

  window.Interface.addEventListener = function(event, listener) {
    window.InterfaceCallbacks.EventListeners[event].push(listener);
  }

  window.Interface.removeEventListener = function(event, listener) {
    var filteredList = window.InterfaceCallbacks.EventListeners[event].filter(function(l) {
      return l != listener;
    });
    window.InterfaceCallbacks.EventListeners[event] = filteredList;
  }
}

exports["addEventListener"] = function(event, listener) {
  window.Interface.addEventListener(event, listener);
}

exports["removeEventListener"] = function(event, listener) {
  window.Interface.removeEventListener(event, listener);
}
