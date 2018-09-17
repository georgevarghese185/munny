const spawn = require("child_process").spawn;

let port = "";
let host = "";
let config = "build/config/webpack.dev.config.js";
let mainModule = ""

process.argv.map((arg, i, argv) => {
  if(arg === "--host") {
    host = "--host " + argv[i + 1];
  }

  if(arg === "--port") {
    port = "--port " + argv[i + 1];
  }

  if(arg === "--test") {
    main = "--main Test.Main"
    config = "build/config/webpack.test.config.js";
  }
})

spawn("concurrently", [`pulp --watch build ${mainModule}`, `webpack-dev-server --config ${config} ${host} ${port}`], {stdio: [0,1,2]});
