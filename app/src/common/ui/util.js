const isDiff = function(obj1, obj2) {
  if(typeof obj1 == "object") {
    let keys = Object.keys(obj1);

    for(let i = 0; i < keys.length; i++) {
      let key = keys[i];
      if(isDiff(obj1[key], obj2[key])) {
        return true;
      }
    }

    return false;
  } else {
    return obj1 !== obj2
  }
}

const updateObject = function(vm, newState, key) {
  if(Array.isArray(vm[key]) && vm[key].length != newState[key].length) {
    vm[key] = newState[key];
  } else {
    Object.keys(vm[key])
      .filter(k => isDiff(vm[key][k], newState[key][k]))
      .map(k => vm.$set(vm[key], k, newState[key][k]));
  }
}

const updateVue = function(vm, newState) {
  Object.keys(newState)
    .map(key => {
      if(typeof newState[key] == "object") {
        updateObject(vm, newState, key);
      } else if(vm[key] != newState[key]) {
        vm[key] = newState;
      }
    })
}

export { updateVue }
