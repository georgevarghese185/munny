module.exports = {
  start: function() {
    let renderFn = function(state){
      console.log("New state: " + JSON.stringify(state));
    }
    return renderFn
  },
  setStateListener: function(stateListener) {
    window.stateListenerTest = stateListener;
  }
}
