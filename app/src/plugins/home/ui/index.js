import HomeScreen from './HomeScreen.vue'
import Vue from 'vue'

const createVue = (id, state, onEvent, setStateListener) => {
  let props = { state, onEvent, setStateListener }
  let vm = new Vue({
    el: id,
    render: createElement => createElement(HomeScreen, { props })
  });
}

const start = (rootId, onEvent) => {
  let stateListener;
  let vueSetup = false;

  let _onEvent = () => {
    let eventName = arguments[0];
    let args = arguments.slice(1);

    onEvent(eventName, args);
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
