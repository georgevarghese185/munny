exports.askImpl = function(question, callback) {
  console.log(question);
  window.answer = function(answer) {
    delete window.answer;
    callback(answer);
  }
}
