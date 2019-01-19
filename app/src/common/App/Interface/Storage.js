exports.storeImpl = function (key, value) {
  window.Interface.storeData(key, value);
};

exports.getImpl = function (key) {
  return window.Interface.getData(key);
};

exports.clearImpl = function (key) {
  window.Interface.clearData(key);
};
