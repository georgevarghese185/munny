import HomeScreen from './HomeScreen.vue'
import Vue from 'vue'

const createVue = (id, initialState, onEvent, setStateListener) => {
  let props = { initialState, onEvent, setStateListener }
  let vm = new Vue({
    el: id,
    render: createElement => createElement(HomeScreen, { props })
  });
}

const start = (rootId, onEvent) => {
  let stateListener;
  let vueSetup = false;

  let _onEvent = function() {
    let args = Array.from(arguments);
    let eventName = args[0];

    onEvent(eventName, args.slice(1));
  }

  let setStateListener = listener => stateListener = listener;

  let updateState = newState => {
    if(!vueSetup) {
      createVue(rootId, newState, _onEvent, setStateListener);
      vueSetup = true;
    } else if(stateListener) {
      stateListener(newState);
    } else {
      console.error("No screen state listener set!");
    }
  }

  return updateState
}

export { start }
