exports["setupLifeCycleCallbacks"] = function() {
  window.InterfaceCallbacks["onPause"] = function() {
    console.log("onPause");
  }

  window.InterfaceCallbacks["onResume"] = function() {
    console.log("onResume");
  }
}
