exports.storeImpl = function (key, value) {
  localStorage[key] = value;
};

exports.getImpl = function (just, nothing, key) {
  if(localStorage.hasOwnProperty(key)) {
    return just(localStorage[key]);
  } else {
    return nothing;
  }
};

exports.clearImpl = function (key) {
  delete localStorage[key];
};
